class UMeltdownScreenPushPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownScreenPushManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Manager == nullptr)
			Manager = TListedActors<AMeltdownScreenPushManager>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Manager != nullptr && Manager.bMashActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Manager == nullptr || !Manager.bMashActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};