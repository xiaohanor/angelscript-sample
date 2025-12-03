class UFlyingCarOfficeAssistedJumpComponent : UActorComponent
{
	UPROPERTY(Transient)
	private FFlyingCarOfficeAssistedJump AssistedJump = FFlyingCarOfficeAssistedJump();

	bool bWaitingForInput;

	void ApplyJump(FFlyingCarOfficeAssistedJump Jump)
	{
		AssistedJump = Jump;
	}

	void ClearJump()
	{
		AssistedJump = FFlyingCarOfficeAssistedJump();
		bWaitingForInput = false;
	}

	FFlyingCarOfficeAssistedJump GetCurrentAssistedJump() const
	{
		return AssistedJump;
	}

	bool IsAssistedJumpActive() const
	{
		return AssistedJump.bValid;
	}
}