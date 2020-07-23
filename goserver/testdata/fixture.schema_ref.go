// Code generated by oa3 (https://github.com/aarondl/oa3). DO NOT EDIT.
// This file is meant to be re-generated in place and/or deleted at any time.
package oa3gen

import (
	"github.com/aarondl/oa3/support"
)

// References to other objects
type Ref struct {
	RefNormal RefTarget         `json:"ref_normal"`
	RefNull   RefTargetNullable `json:"ref_null,omitempty"`
}

// ValidateSchemaRef validates the object and returns
// errors that can be returned to the user.
func (o Ref) ValidateSchemaRef() support.Errors {
	var ctx []string
	var ers []error
	var errs support.Errors
	_, _ = ers, errs

	errs = support.AddErrs(errs, "", ers...)

	return errs
}
