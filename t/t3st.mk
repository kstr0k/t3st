T3ST_PROVE_SHELLS = 'sh,bash,busybox sh'

.PHONY: t3st-prove new

t3st-prove:
	git -c t3st.prove-shells=$(T3ST_PROVE_SHELLS) t3st-prove

new: new.t new-e.t
	@echo '## Rename new.t and new-e.t and edit'

new.t: t3st-lib/t3st-new.t.0
	cp t3st-lib/t3st-new.t.0 new.t

new-e.t: t3st-lib/t3st-e.t.0
	ln -s t3st-lib/t3st-e.t.0 new-e.t
