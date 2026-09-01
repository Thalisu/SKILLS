#ifndef SVC_H
#define SVC_H

int fetch_user(int id);

static inline int max_retries(void) { return 3; }

#endif
