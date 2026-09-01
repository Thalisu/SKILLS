package svc

type User struct {
	ID int
}

type Svc struct{}

func NewSvc() *Svc {
	return &Svc{}
}

func (s *Svc) FetchUser(id int) (*User, error) {
	return &User{ID: id}, nil
}
