struct FDentistBossToolScraperRestrainPlayerActivationParams
{
	AHazePlayerCharacter RestrainedPlayer;
}

class UDentistBossToolScraperRestrainPlayerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolScraper Scraper;
	ADentistBoss Dentist;
	UDentistBossTargetComponent TargetComp;

	UDentistBossSettings Settings;

	AHazePlayerCharacter RestrainedPlayer;
	UDentistToothPlayerComponent ToothComp;

	FHazeAcceleratedQuat AccToothRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Scraper = Cast<ADentistBossToolScraper>(Owner);

		Dentist = TListedActors<ADentistBoss>().GetSingle();
		TargetComp = UDentistBossTargetComponent::Get(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistBossToolScraperRestrainPlayerActivationParams& Params) const
	{
		if(!Scraper.bActive)
			return false;

		if(!Scraper.RestrainedPlayer.IsSet())
			return false;

		Params.RestrainedPlayer = Scraper.RestrainedPlayer.Value;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Scraper.bActive)
			return true;

		if(!Scraper.RestrainedPlayer.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistBossToolScraperRestrainPlayerActivationParams Params)
	{
		RestrainedPlayer = Params.RestrainedPlayer;
		RestrainedPlayer.BlockCapabilities(CapabilityTags::Movement, this);
		RestrainedPlayer.AttachToComponent(Scraper.TipRoot, AttachmentRule = EAttachmentRule::SnapToTarget);
		RestrainedPlayer.ActorRelativeLocation = FVector::DownVector * DentistBossMeasurements::HookAttachUpOffset;
		
		auto ResponseComp = UDentistToothMovementResponseComponent::GetOrCreate(RestrainedPlayer);
		ResponseComp.OnDashImpact = EDentistToothDashImpactResponse::Backflip;
		RestrainedPlayer.CapsuleComponent.SetCollisionObjectType(ECollisionChannel::ECC_WorldDynamic);
		RestrainedPlayer.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
		Dentist.HasSwatAmnesty[RestrainedPlayer] = true;

		ToothComp = UDentistToothPlayerComponent::Get(RestrainedPlayer);
		ToothComp.bHooked = true;
		FQuat CurrentMeshRotation = ToothComp.GetMeshWorldRotation();
		AccToothRotation.SnapTo(CurrentMeshRotation, ToothComp.GetMeshAngularVelocity());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ToothComp.bHooked = false;

		RestrainedPlayer.DetachFromActor(EDetachmentRule::KeepWorld);
		RestrainedPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		RestrainedPlayer.CapsuleComponent.SetCollisionObjectType(ECollisionChannel::PlayerCharacter);
		RestrainedPlayer.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		Dentist.HasSwatAmnesty[RestrainedPlayer] = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat TargetRotation = FQuat::MakeFromZX(-Scraper.MeshComp.ForwardVector, RestrainedPlayer.Mesh.ForwardVector);

		AccToothRotation.AccelerateTo(TargetRotation, 0.5, DeltaTime);
		ToothComp.SetMeshWorldRotation(AccToothRotation.Value, this);
	}
}