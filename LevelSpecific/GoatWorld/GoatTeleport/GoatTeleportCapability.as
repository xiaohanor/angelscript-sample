class UGoatTeleportCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 50;

	UGoatTeleportPlayerComponent TeleportComp;
	UGenericGoatPlayerComponent GoatComp;

	float TeleportDuration = 0.1;

	bool bEffectSpawned = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TeleportComp = UGoatTeleportPlayerComponent::Get(Player);
		GoatComp = UGenericGoatPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (!TeleportComp.bValidTarget)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= TeleportDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bEffectSpawned = false;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(TeleportComp.DisapperEffect, Player.ActorCenterLocation);

		Player.SmoothTeleportActor(TeleportComp.PreviewActor.ActorLocation, TeleportComp.PreviewActor.ActorRotation, this, TeleportDuration);

		FHazeCameraImpulse CamImpulse;
		CamImpulse.CameraSpaceImpulse = FVector(-5000.0, 0.0, 0.0);
		CamImpulse.AngularImpulse = FRotator(0.0, 0.0, 10.0);
		CamImpulse.Dampening = 0.7;
		CamImpulse.ExpirationForce = 100.0;
		Player.ApplyCameraImpulse(CamImpulse, this);

		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(30.0, this, TeleportDuration * 5.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UCameraSettings::GetSettings(Player).FOV.Clear(this);

		Player.Mesh.SetRelativeScale3D(FVector(1.0));
		GoatComp.CurrentGoat.GoatMesh.SetRelativeScale3D(FVector(1.5));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float DurationAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, TeleportDuration), FVector2D(0.0, 1.0), ActiveDuration);
		float ScaleAlpha = TeleportComp.ScaleCurve.GetFloatValue(DurationAlpha);

		if (ScaleAlpha >= 0.75)
			SpawnEffect();

		float Scale = Math::Lerp(1.0, 0.0, ScaleAlpha);
		Player.Mesh.SetRelativeScale3D(FVector(Scale));
		GoatComp.CurrentGoat.GoatMesh.SetRelativeScale3D(FVector(1.5 * Scale));
	}

	void SpawnEffect()
	{
		if (bEffectSpawned)
			return;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(TeleportComp.AppearEffect, Player.ActorCenterLocation);
	}
}