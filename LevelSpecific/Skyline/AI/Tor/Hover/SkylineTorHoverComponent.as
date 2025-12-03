class USkylineTorHoverComponent : UActorComponent
{
	private USkylineTorThrusterManagerComponent ThrusterManagerComp;
	private TInstigated<bool> bHoverInternal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ThrusterManagerComp = USkylineTorThrusterManagerComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	bool GetbHover() property
	{
		return bHoverInternal.Get();
	}

	UFUNCTION()
	void StartHover(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		bool bWasEnabled = bHoverInternal.Get();
		bHoverInternal.Apply(true, Instigator, Priority);
		SetThrusters(bWasEnabled);
	}

	UFUNCTION()
	void StopHover(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		bool bWasEnabled = bHoverInternal.Get();
		bHoverInternal.Apply(false, Instigator, Priority);
		SetThrusters(bWasEnabled);
	}

	UFUNCTION()
	void ClearHover(FInstigator Instigator)
	{
		bool bWasEnabled = bHoverInternal.Get();
		bHoverInternal.Clear(Instigator);
		SetThrusters(bWasEnabled);
	}

	private void SetThrusters(bool bWasEnabled)
	{
		if(!bWasEnabled && bHoverInternal.Get())
			ThrusterManagerComp.StartThrusters(this);
		if(bWasEnabled && !bHoverInternal.Get())
			ThrusterManagerComp.StopThrusters(this);
	}
}