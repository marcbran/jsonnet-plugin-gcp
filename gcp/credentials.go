package gcp

import (
	"context"
	"fmt"
)

type Credentials struct {
	Token string
}

type CredentialsByRequest func(ctx context.Context, ci CallInput) (Credentials, error)

func noCredentials(context.Context, CallInput) (Credentials, error) {
	return Credentials{}, fmt.Errorf("no credentials configured")
}
