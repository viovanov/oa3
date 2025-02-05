{{- $.Import "net/http" -}}
{{- $.Import "net/http/httputil" -}}
{{- $.Import "context" -}}
{{- $.Import "fmt" -}}
{{- $.Import "time" -}}

type ctxKey string

const (
	ctxKeyDebug ctxKey = "debug"
)

{{template "client_urls" .}}

var (
	apiHTTPClient = &http.Client{Timeout: time.Second * 5}
)

// Client is a generated package for consuming an openapi spec.
{{- if $.Spec.Info.Description}}
//
// {{wrapWith 70 "\n// " (trimSuffix "\n" $.Spec.Info.Description)}}
{{end -}}
type Client struct {
	httpClient *http.Client
	httpHandler http.Handler
	{{- $.Import "golang.org/x/time/rate"}}
	limiter *rate.Limiter

	url URLBuilder
}

// WithDebug creates a context that will emit debugging information to stdout
// for each request.
func WithDebug(ctx context.Context) context.Context {
	return context.WithValue(ctx, ctxKeyDebug, "t")
}

func hasDebug(ctx context.Context) bool {
	v := ctx.Value(ctxKeyDebug)
	return v != nil && v.(string) == "t"
}

// NewClient constructs an api client, optionally using a supplied http.Client
// to be able to add instrumentation or customized timeouts.
//
// If nil is supplied then this package's generated apiHTTPClient is used which
// has reasonable defaults for timeouts.
//
// It also takes an optional rate limiter to implement rate limiting.
func NewClient(httpClient *http.Client, limiter *rate.Limiter, baseURL URLBuilder) Client {
	{{- $topLevelURL := "" -}}
	{{- with $servers := $.Spec.Servers -}}
		{{- $topLevelURL = (index $servers 0).URL | filterNonIdentChars | title -}}
	{{- end}}
	client := Client{httpClient: apiHTTPClient, limiter: limiter, url: baseURL}
	if httpClient != nil {
		client.httpClient = httpClient
	}
	return client
}

// NewLocalClient constructs an api client, but takes in a handler to call
// with the prepared requests instead of an http client that will touch the
// network. Useful for testing.
func NewLocalClient(httpHandler http.Handler) Client {
	return Client{httpHandler: httpHandler, url: URL("http://localhost")}
}

// WithURL sets the url for this client, the client is a shallow clone and
// therefore still shares the same http client, handler and rate limiter.
func (c Client) WithURL(url URLBuilder) Client {
	newClient := c
	newClient.url = url
	return newClient
}

func (c Client) doRequest(ctx context.Context, req *http.Request) (*http.Response, error) {
	if c.limiter != nil {
		if err := c.limiter.Wait(ctx); err != nil {
			return nil, err
		}
	}

	if hasDebug(ctx) {
		reqDump, err := httputil.DumpRequestOut(req, true)
		if err != nil {
			return nil, fmt.Errorf("failed to emit debugging info: %w", err)
		}
		fmt.Printf("%s\n", reqDump)
	}

	var resp *http.Response
	if c.httpHandler != nil {
		{{- $.Import "net/http/httptest"}}
		w := httptest.NewRecorder()
		c.httpHandler.ServeHTTP(w, req)
		resp = w.Result()
	} else {
		var err error
		resp, err = c.httpClient.Do(req)
		if err != nil {
			return nil, err
		}
	}

	if hasDebug(ctx) {
		respDump, err := httputil.DumpResponse(resp, true)
		if err != nil {
			return nil, fmt.Errorf("failed to emit debugging info: %w", err)
		}
		fmt.Printf("%s\n", respDump)
	}

	return resp, nil
}

{{template "responses" $}}
