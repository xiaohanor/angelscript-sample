class UTazerBotSocketCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);

	// Gotta update spline after PerchSpline capability has ticked,
	// player overshoots and hovers otherwise
	default TickGroup = EHazeTickGroup::Gameplay;

	ATazerBot TazerBot;

	float AcceleratedExtensionTarget;

	bool bPerchSplineEnabled;
	bool bNetExtending;
	bool bFullyExtended;

	// Original bone locations
	FVector BaseRelativeLocation;
	float ShaftOffset;
	float TipOffset;

	ATazerBotSocket Socket;

	FHazeAcceleratedFloat AccLocSpeed;
	FHazeAcceleratedFloat AccRotSpeed;

	FVector OriginalAttachLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);

		BaseRelativeLocation = TazerBot.MeshComponent.GetBoneLocationByName(n"Tazer1", EBoneSpaces::ComponentSpace) - TazerBot.MeshComponent.GetBoneLocationByName(n"Head", EBoneSpaces::ComponentSpace);
		ShaftOffset = (TazerBot.MeshComponent.GetBoneLocationByName(n"Tazer2", EBoneSpaces::ComponentSpace).X - BaseRelativeLocation.X);
		TipOffset = (TazerBot.MeshComponent.GetBoneLocationByName(n"Tazer3", EBoneSpaces::ComponentSpace).X - BaseRelativeLocation.X - ShaftOffset);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TazerBot.bDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TazerBot.bDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Socket = TazerBot.CurrentSocket;

		OriginalAttachLoc = Socket.BotAttachComp.RelativeLocation;
		FVector InitialLoc = TazerBot.MeshComponent.GetSocketLocation(n"Tazer3");
		InitialLoc.Z = TazerBot.ActorLocation.Z;
		Socket.BotAttachComp.SetWorldLocation(InitialLoc);

		FRotator InitialRot = (TazerBot.ActorLocation - Socket.BotAttachComp.WorldLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();
		Socket.BotAttachComp.SetWorldRotation(InitialRot);
		TazerBot.AttachToComponent(Socket.BotAttachComp, NAME_None, EAttachmentRule::KeepWorld);

		TazerBot.SetHackingAllowed(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccLocSpeed.AccelerateTo(1600.0, 1.5, DeltaTime);
		FVector AttachLoc = Math::VInterpConstantTo(Socket.BotAttachComp.RelativeLocation, OriginalAttachLoc, DeltaTime, AccLocSpeed.Value);
		Socket.BotAttachComp.SetRelativeLocation(AttachLoc);

		FVector Loc = Math::VInterpConstantTo(TazerBot.ActorRelativeLocation, FVector::ZeroVector, DeltaTime, AccLocSpeed.Value);
		TazerBot.SetActorRelativeLocation(Loc);

		AccRotSpeed.AccelerateTo(100.0, 2.0, DeltaTime);
		FRotator Rot = Math::RInterpConstantShortestPathTo(Socket.BotAttachComp.RelativeRotation, FRotator::ZeroRotator, DeltaTime, AccRotSpeed.Value);
		Socket.BotAttachComp.SetRelativeRotation(Rot);

		if (Loc.Equals(FVector::ZeroVector))
		{
			Socket.BotFullyConnected();
		}

		const float Offset = TazerBot.Settings.ShaftLength/3.0;

		FTransform TurretTransform = TazerBot.MeshComponent.GetBoneTransformByName(n"Head", EBoneSpaces::WorldSpace);
		const FVector BaseWorldLocation = TurretTransform.TransformPosition(BaseRelativeLocation);

		// We don't want tazer rod to pitch or roll
		FRotator TurretRotation = TurretTransform.Rotator();
		TurretRotation.Pitch = TurretRotation.Roll = 0;
		FVector TazerForwardVector = TurretRotation.Vector();

		float DistToSocket = Socket.BotAttachComp.WorldLocation.Dist2D(TazerBot.ActorLocation, FVector::UpVector);
		float RodExtensionFraction = Math::Lerp(0.0, 1.0, DistToSocket/TazerBot.Settings.ShaftLength);

		// Base - inherit head bone transform
		float BaseExtensionMultiplier = Math::Saturate(RodExtensionFraction / 0.3);
		FVector BaseBoneLocation = BaseWorldLocation + TazerForwardVector * Offset * BaseExtensionMultiplier;
		TazerBot.MeshComponent.SetBoneLocationByName(n"Tazer1", BaseBoneLocation, EBoneSpaces::WorldSpace);

		// Shaft (giggity)
		float ShaftExtensionMultiplier = Math::Saturate(Math::Max(0.0, RodExtensionFraction - 0.33) / 0.3); // -0.4
		FVector ShaftBoneLocation = BaseBoneLocation + TazerForwardVector * (Offset * ShaftExtensionMultiplier + ShaftOffset);
		TazerBot.MeshComponent.SetBoneLocationByName(n"Tazer2", ShaftBoneLocation, EBoneSpaces::WorldSpace);

		// // (Just the) Tip
		float TipExtensionMultiplier = Math::Saturate(Math::Max(0.0, RodExtensionFraction - 0.66) / 0.2); // -0.8
		FVector TipBoneLocation = ShaftBoneLocation + TazerForwardVector * (Offset * TipExtensionMultiplier + TipOffset);
		TazerBot.MeshComponent.SetBoneLocationByName(n"Tazer3", TipBoneLocation, EBoneSpaces::WorldSpace);
	}
}