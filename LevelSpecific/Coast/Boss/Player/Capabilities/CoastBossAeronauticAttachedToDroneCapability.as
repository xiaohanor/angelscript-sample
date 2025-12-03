struct FCoastBossAeronauticAttachedToDroneActivationParams
{
	FVector SnapLocation;
	FRotator SnapRotation;
}

struct FCoastBossAeronauticAttachedToDroneDeactivationParams
{
	bool bNatural = false;
}

class UCoastBossAeronauticAttachedToDroneCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	
	FCoastBossAeronauticAttachedToDroneActivationParams ActivationParams;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	ACoastBossActorReferences References;

	UCoastBossAeronauticComponent AirMoveDataComp;
	UPlayerHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AirMoveDataComp = UCoastBossAeronauticComponent::GetOrCreate(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCoastBossAeronauticAttachedToDroneActivationParams & Params) const
	{
		Params.SnapLocation = Player.ActorLocation;
		Params.SnapRotation = Player.ActorRotation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FCoastBossAeronauticAttachedToDroneDeactivationParams& Params) const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCoastBossAeronauticAttachedToDroneActivationParams Params)
	{
		Player.ApplySettings(AirMoveDataComp.RespawnEffectSettings, this);
		HealthComp.OnDeathTriggered.AddUFunction(this, n"OnDeath");
		ActivationParams = Params;
		if (Player.IsMio())
			AirMoveDataComp.AttachedToShip = References.MioDrone;
		else
			AirMoveDataComp.AttachedToShip = References.ZoeDrone;

		
		//This enables the VFX that is in the instance of the BP
		AirMoveDataComp.AttachedToShip.OnStartShip();

		// If we do an entry sequence?
		// Can we make it seamless..?

		// if (AirMoveDataComp.AttachedToDrone.AttachParentActor != nullptr)
		// {
		// 	ASanctuaryCompanionAviationSwoopSequence PlayingSequence = Cast<ASanctuaryCompanionAviationSwoopSequence>(AirMoveDataComp.AttachedToDrone.AttachParentActor);
		// 	if (PlayingSequence != nullptr)
		// 		PlayingSequence.OnDone.AddUFunction(this, n"Ride");
		// }
		// else
		{
			Ride();
		}
	}

	UFUNCTION()
	private void Ride()
	{
		AirMoveDataComp.bAttached = true;
		AirMoveDataComp.AttachedToShip.AttachRootComponentTo(Player.RootComponent, NAME_None, EAttachLocation::SnapToTarget, true);

		FVector WorldLocation = ActivationParams.SnapLocation;
		WorldLocation += ActivationParams.SnapRotation.RotateVector(-AirMoveDataComp.AttachedToShip.AttachPlayerToComponent.RelativeLocation);
		AirMoveDataComp.AttachedToShip.SetActorLocation(WorldLocation);
		AirMoveDataComp.AttachedToShip.SetActorRotation(ActivationParams.SnapRotation);

		// AirMoveDataComp.AttachedToShip.AttachPlayerToComponent.SetRelativeLocation(FVector(0.0, 0.0, 125.0));
		AirMoveDataComp.AttachedToShip.AttachPlayerToComponent.SetWorldScale3D(Player.Mesh.GetWorldScale());
		
		Player.MeshOffsetComponent.AttachToComponent(AirMoveDataComp.AttachedToShip.AttachPlayerToComponent, n"", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		Player.MeshOffsetComponent.SnapToRelativeTransform(this, AirMoveDataComp.AttachedToShip.AttachPlayerToComponent, FTransform::Identity);

		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Outline, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCoastBossAeronauticAttachedToDroneDeactivationParams Params)
	{
		Player.ClearSettingsByInstigator(this);
		HealthComp.OnDeathTriggered.Unbind(this, n"OnDeath");

		if (AirMoveDataComp.bAttached)
		{
			AirMoveDataComp.bAttached = false;
			Player.UnblockCapabilities(CapabilityTags::Collision, this);
			Player.UnblockCapabilities(CapabilityTags::Outline, this);
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

			Player.ClearSettingsByInstigator(this);

			Player.GetMeshOffsetComponent().ClearOffset(this);
			Player.MeshOffsetComponent.AttachToComponent(Player.RootOffsetComponent);
			Player.MeshOffsetComponent.SetRelativeTransform(FTransform::Identity);
			Player.ClearCameraSettingsByInstigator(this);
			AirMoveDataComp.AttachedToShip.DetachFromActor();
		}
	}

	UFUNCTION()
	private void OnDeath()
	{
		FCoastBossAeronauticPlayerDiedEffectData Data;
		Data.PlaneToAttachTo = References.CoastBossPlane2D.Root;
		Data.Player = Player;
		UCoastBossAeuronauticPlayerEventHandler::Trigger_Died(Player, Data);
	}
};