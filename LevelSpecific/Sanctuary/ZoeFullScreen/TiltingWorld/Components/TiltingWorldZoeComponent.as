class UTiltingWorldZoeComponent : UActorComponent
{
	bool bOverrideWorldUp = false;
	bool bResetWorldUp = false;
	FVector WorldUp;

	void SetWorldUp(FVector InWorldUp)
	{
		bOverrideWorldUp = true;
		WorldUp = InWorldUp;
	}

	void ResetWorldUp()
	{
		bResetWorldUp = true;
		bOverrideWorldUp = false;
	}
}