class UFlyingCarOfficeCrashComponent : UActorComponent
{
	FFlyingCarOfficeCrashParams ActiveCrashParams;
	bool bCrashing;

	void Crash(FFlyingCarOfficeCrashParams CrashParams)
	{
		ActiveCrashParams = CrashParams;

		bCrashing = true;
	}
}