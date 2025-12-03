class USanctuaryCompanionAviationShowAttackDiscCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	USanctuaryCompanionMegaCompanionPlayerComponent CompanionComp;

	bool bLateActivated = false;

	FHazeAcceleratedFloat AccPostKillScale;
	EAviationState PreviousState;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		CompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Owner);
		AccPostKillScale.SnapTo(1.0);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!IsInStateHandledByThisCapability())
			return false;

		if (CompanionComp.AttackDisc == nullptr)
			return false;

		if (CompanionComp.SyncedDiscLocation.Value.Size() < KINDA_SMALL_NUMBER)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (IsInStateHandledByThisCapability())
			return false;

		if (Math::Abs(AccPostKillScale.Velocity) > KINDA_SMALL_NUMBER)
			return false;

		return true;
	}

	bool IsInStateHandledByThisCapability() const
	{
		if (AviationComp.AviationState == EAviationState::Attacking)
			return true;

		if (AviationComp.AviationState == EAviationState::AttackingSuccessCircling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bLateActivated = false;
	}

	void LateActivate()
	{
		bLateActivated = true;
		if (CompanionComp == nullptr)
			CompanionComp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Owner);

		UpdateSyncedVFXMesh(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UpdateSyncedVFXMesh(0.0);
		CompanionComp.AttackDisc.MeshVFX.SetVisibility(false, true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bLateActivated && ActiveDuration > 1.5)
			LateActivate();
		else if (bLateActivated)
			UpdateSyncedVFXMesh(DeltaTime);
	}

	void UpdateSyncedVFXMesh(float DeltaTime)
	{
		CompanionComp.AttackDisc.SetActorLocation(CompanionComp.SyncedDiscLocation.Value);
		CompanionComp.AttackDisc.SetActorRotation(FRotator::MakeFromZX(CompanionComp.SyncedDiscUpvector.Value, FVector::ForwardVector));
		float Radius = Math::Max(0.1, CompanionComp.SyncedDiscRadius.Value);
		float Scale = Radius / CompanionComp.AttackDisc.MeshRadius;

		bool bJustSucceeded = PreviousState != EAviationState::AttackingSuccessCircling && AviationComp.AviationState == EAviationState::AttackingSuccessCircling;
		if (bJustSucceeded)
			AccPostKillScale.SnapTo(Scale);
		PreviousState = AviationComp.AviationState;

		if (AviationComp.AviationState == EAviationState::AttackingSuccessCircling)
		{
			AccPostKillScale.SpringTo(0.0, 50.0, 0.7, DeltaTime);
			Scale = Math::Max(0.1, AccPostKillScale.Value);
		}

		CompanionComp.AttackDisc.SetActorScale3D(FVector::OneVector * Scale);

		bool bVisibleRadius = Radius < Math::Lerp(AviationComp.Settings.StranglingMaxRadius, AviationComp.Settings.StranglingMinRadius, 0.5);
		bool bShouldBeVisible = bVisibleRadius || AviationComp.AviationState == EAviationState::AttackingSuccessCircling;
		if (CompanionComp.AttackDisc.MeshVFX.IsVisible() != bShouldBeVisible)
			CompanionComp.AttackDisc.MeshVFX.SetVisibility(bShouldBeVisible, true);
		if (!bShouldBeVisible)
			AccPostKillScale.SnapTo(0.0);
	}
};