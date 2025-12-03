class USkylineTorOpportunityAttackComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeCameraSpringArmSettingsDataAsset> AttackCameraSettings;

	UPROPERTY(EditDefaultsOnly)
	TArray<UHazeCameraSpringArmSettingsDataAsset> FailCameraSettings;

	bool bIsOpportunityAttackSequenceActive  = false;
	
	bool bStartedSequence;
	private TInstigated<bool> bInternalCanStartSequence;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bInternalCanStartSequence.SetDefaultValue(false);
	}

	UHazeCameraSpringArmSettingsDataAsset GetAttackCameraSettings(int Index)
	{
		if (AttackCameraSettings.IsValidIndex(Index))
			return AttackCameraSettings[Index];
		if (AttackCameraSettings.Num() > 0)
			return AttackCameraSettings.Last();
		return nullptr;
	}

	UHazeCameraSpringArmSettingsDataAsset GetFailCameraSettings(int Index)
	{
		if (FailCameraSettings.IsValidIndex(Index))
			return FailCameraSettings[Index];
		if (FailCameraSettings.Num() > 0)
			return FailCameraSettings.Last();
		return nullptr;
	}

	bool GetbCanStartSequence() property
	{
		return bInternalCanStartSequence.Get();
	}

	void Enable(FInstigator Instigator)
	{
		bInternalCanStartSequence.Apply(true, Instigator);
		bStartedSequence = false;
	}

	void Disable(FInstigator Instigator)
	{
		bInternalCanStartSequence.Clear(Instigator);
		bStartedSequence = false;
	}
}
