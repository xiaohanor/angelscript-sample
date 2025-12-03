class UIslandRedBlueOverheatAssaultUserComponent : UActorComponent
{
	access ReadOnly = private, * (readonly);

	float OverheatAlpha = 0.0;
	access:ReadOnly bool bIsOverheated = false;
	float TimeOfOverheat;

	void SetIsOverheated(bool bState)
	{
		bIsOverheated = bState;

		if(bIsOverheated)
			TimeOfOverheat = Time::GetGameTimeSeconds();
	}
}