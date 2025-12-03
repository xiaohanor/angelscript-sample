namespace VortexSandFish
{
	UFUNCTION(BlueprintPure)
	AVortexSandFish GetVortexSandFish()
	{
		return Desert::GetManager().VortexSandfish;
	}
}