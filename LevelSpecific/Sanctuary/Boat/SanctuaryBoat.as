namespace SanctuaryBoatTags
{
	const FName Boat = n"Boat";
	const FName BoatImpact = n"BoatImpact";
	const FName BoatPlayerConstrain = n"BoatPlayerConstrain";
}

class ASanctuaryBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
//	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
//	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMovementComp;
	default InheritMovementComp.Shape.Type = EHazeShapeType::Sphere;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent WaterRim;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactFF;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UDarkPortalForceAnchorComponent ForceAnchorComp;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UDynamicWaterEffectDecalComponent DynamicWaterEffectDecalComp;
	default DynamicWaterEffectDecalComp.Strength = 5.0;
	default DynamicWaterEffectDecalComp.RelativeScale3D = FVector::OneVector * 3.0;
	default DynamicWaterEffectDecalComp.bCircle = true;
	default DynamicWaterEffectDecalComp.Contrast = 512;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bCanRerunMovement = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;
	default SyncedPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;
	default SyncedPosition.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerCapabilityClasses.Add(USanctuaryBoatUserConstrainCapability);
	default RequestCapabilityComp.PlayerCapabilityClasses.Add(USanctuaryBoatUserDarkPortalAimRangeCapability);

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;
	default DarkPortalResponseComp.bAllowMultiComponentGrab = true;
	default DarkPortalResponseComp.PullForce = 1000.0;

	ADarkPortalActor DarkPortal;

	FVector Velocity;
	FVector AngularVelocity;
	float AngularDrag = 2.0;
	float Drag = 1.0;

	FVector AccumulatedImpulse;
	FVector AccumulatedAngularImpulse;

	FVector Gravity = -FVector::UpVector * 980.0 * 3.0;

	UPROPERTY(EditAnywhere)
	float BoatRadius = 225.0;

	UPROPERTY(EditAnywhere)
	float GrabDistance = 2000.0;

	UPROPERTY(EditAnywhere)
	int GrabTargets = 5;

	UPROPERTY(EditAnywhere)
	float GrabTargetsSpreadAngle = 10.0;

	UPROPERTY(EditAnywhere)
	float GrabTargetsInset = 30.0;

	UPROPERTY(EditAnywhere)
	float WaterHeight = 1000.0;

	UPROPERTY(EditAnywhere)
	float PlayerWeight = 200.0;

	UPROPERTY(EditAnywhere)
	float PlayerTorqueScale = 2.0;

	UPROPERTY(EditAnywhere)
	float PlayerImpulseScale = 0.1;

	UPROPERTY(EditAnywhere)
	float BuoyantScale = 1.0;

	UPROPERTY(EditInstanceOnly)
	AActor WaterHeighRef;

	TArray<AHazePlayerCharacter> ImpactingPlayers;

	ASlidingDisc SuperHackySnapToDisc = nullptr;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Collision.SphereRadius = BoatRadius;
		InheritMovementComp.Shape.SphereRadius = BoatRadius;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GhostTownDevToggles::GhostTownCategory.MakeVisible();
		SetActorControlSide(Game::Zoe);

		TArray<UPrimitiveComponent> Primitives;
		GetComponentsByClass(Primitives);

		for (auto Primitive : Primitives)
			Primitive.SetShadowPriorityRuntime(EShadowPriority::GameplayElement);

		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");		
		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");		
		DarkPortalResponseComp.OnAttached.AddUFunction(this, n"HandlePortalAttached");
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpactBegin");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandlePlayerImpactEnd");

		CreateGrabTargets();

		if(WaterHeighRef!=nullptr)
			WaterHeight = WaterHeighRef.GetActorLocation().Z;

		MoveComp.OverrideResolver(USanctuaryBoatMovementResolver, this);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateGrabTargetLocation();
		
		float HeightAboveWater = Math::Saturate((ActorLocation.Z - WaterHeight - 50) / 50);
		HeightAboveWater += Math::Sin(Time::GameTimeSeconds * 5.0) * 0.1;

		DynamicWaterEffectDecalComp.Strength = Math::Lerp(3.0, 8.0, HeightAboveWater);
		DynamicWaterEffectDecalComp.RelativeScale3D  = FVector::OneVector * Math::Lerp(2.0, 4.0, HeightAboveWater);

//		DrawDebug();
	}

	UFUNCTION()
	private void HandlePlayerImpactBegin(AHazePlayerCharacter Player)
	{
		if (ImpactingPlayers.AddUnique(Player))
		{
			auto PlayerMoveComp = UHazeMovementComponent::Get(Player);
			AddImpulse(Player.ActorLocation, PlayerMoveComp.PreviousVelocity * PlayerImpulseScale);
		}
	}

	UFUNCTION()
	private void HandlePlayerImpactEnd(AHazePlayerCharacter Player)
	{
		ImpactingPlayers.Remove(Player);
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		USanctuaryBoatEventHandler::Trigger_Grabbed(this);
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		USanctuaryBoatEventHandler::Trigger_Released(this);
	}

	UFUNCTION()
	private void HandlePortalAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
	}

	UFUNCTION()
	void SetGrabDistance(float Distance)
	{
		TArray<UDarkPortalTargetComponent> DarkPortalTargetComps;
		GetComponentsByClass(DarkPortalTargetComps);
		for (auto DarkPortalTargetComp : DarkPortalTargetComps)
			DarkPortalTargetComp.MaximumDistance = Distance;
	}

	void CreateGrabTargets()
	{
		float AngleOffset = (GrabTargets - 1) * GrabTargetsSpreadAngle * 0.5;
		for (int i = 0; i < GrabTargets; i++)
		{
			FName GrabTargetName = FName(GetName() + "_UDarkPortalTargetComponent_" + i);
			UDarkPortalTargetComponent GrabTarget = UDarkPortalTargetComponent::Create(this, GrabTargetName);
			GrabTarget.MaximumDistance = GrabDistance;
			GrabTarget.bLimitAngle = true;
			GrabTarget.LimitedAngle = 90.0;
			
			GrabTarget.AttachToComponent(ForceAnchorComp);

			FVector Location = FVector(Math::Cos(Math::DegreesToRadians(i * GrabTargetsSpreadAngle - AngleOffset)) * (BoatRadius - GrabTargetsInset), Math::Sin(Math::DegreesToRadians(i * GrabTargetsSpreadAngle - AngleOffset)) * (BoatRadius - GrabTargetsInset), 0.0);
			GrabTarget.RelativeLocation = Location -FVector::ForwardVector * BoatRadius;
			GrabTarget.RelativeRotation = FRotator::MakeFromZ(Location);
		}
	}

	void UpdateGrabTargetLocation()
	{
		if (DarkPortal == nullptr)
		{
			for (auto Player : Game::Players)
			{
				UDarkPortalUserComponent DarkPortalUserComp = UDarkPortalUserComponent::Get(Player);
				if (DarkPortalUserComp != nullptr)
					DarkPortal = DarkPortalUserComp.Portal;
			}

			if (DarkPortal == nullptr)
				return;
		}

		if (DarkPortal.IsGrabbingAny())
			return;

		FVector ToDarkPortal = (DarkPortal.ActorLocation - Pivot.WorldLocation).VectorPlaneProject(Pivot.UpVector).SafeNormal * BoatRadius;
		FVector Location = Pivot.WorldLocation + ToDarkPortal;
		ForceAnchorComp.SetWorldLocationAndRotation(Location, FQuat::MakeFromZX(Pivot.UpVector, ToDarkPortal));
	}

	FVector GetGrabForce() property
	{
		FVector Force = FVector::ZeroVector;
		for (auto& Grab : DarkPortalResponseComp.Grabs)
			Force += Grab.ConsumeForce();

		for (auto& Attach : DarkPortalResponseComp.Attaches)
			Force += Attach.ConsumeForce();

		return Force;
	}

	FVector GetBuoyantForce() property
	{
		float Force = Math::Min(0.0, (ActorLocation.Z - BoatRadius) - WaterHeight) * -20.0 * BuoyantScale;
//		PrintToScreen("" + Force, 0.0, FLinearColor::Green);
		return -Gravity.SafeNormal * Force;
	}

	FVector GetDragForce() property
	{
		return Velocity * Drag;
	}

	FVector GetAngularDragTorque() property
	{
		return AngularVelocity * AngularDrag;
	}

	FVector GetPlayerImpactTorque() property
	{
		FVector ImpactTorque = FVector::ZeroVector;
		for (auto ImpactingPlayer : ImpactingPlayers)
		{
			if (ImpactingPlayer.IsPlayerDead())
				continue;

			ImpactTorque += LinearToTorque(ImpactingPlayer.ActorLocation, -FVector::UpVector * PlayerWeight * PlayerTorqueScale);
		}

		return ImpactTorque;
	}

	FVector GetFloatingTorque() property
	{
		FVector Torque = Pivot.WorldTransform.InverseTransformVectorNoScale(-(Pivot.UpVector).CrossProduct(Gravity.SafeNormal) * 30.0);

		return Torque;
//		return -(Pivot.UpVector).CrossProduct(Gravity.SafeNormal) * 30.0;
	}

	FVector GetPlayerImpactForce() property
	{
		FVector ImpactForce = FVector::ZeroVector;
		for (auto ImpactingPlayer : ImpactingPlayers)
		{
			if (ImpactingPlayer.IsPlayerDead())
				continue;

			ImpactForce += Gravity.SafeNormal * PlayerWeight;
		}

		return ImpactForce;
	}

	void ActivateForceFeedBackAndCameraShake()
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	void ActivateForceFeedBack()
	{
		ForceFeedback::PlayWorldForceFeedback(ImpactFF, ActorLocation, false, this, 500, 700, 1.0, 6.0, EHazeSelectPlayer::Both);
	}

	FVector GetStreamForce() property
	{
		int ActiveStreamForces = 0;
		FVector Force;
		
		TListedActors<ASanctuaryBoatStreamVolume> StreamVolumes;
		for (auto StreamVolume : StreamVolumes)
		{
			if (Shape::IsPointInside(StreamVolume.Shape.CollisionShape, StreamVolume.ActorTransform, ActorLocation))
			{
				FVector ToTarget = StreamVolume.StreamTargetLocation - ActorLocation;
				FVector Direction = ToTarget.SafeNormal;
				float Strength = Math::Min(StreamVolume.Force, ToTarget.Size());
				Force += Direction * Strength;
				ActiveStreamForces++;
			}
		}

		TListedActors<ASanctuaryBoatStreamSpline> StreamSplines;
		for (auto StreamSpline : StreamSplines)
		{
			if (Shape::IsPointInside(StreamSpline.Volume.CollisionShape, StreamSpline.Volume.WorldTransform, ActorLocation))
			{
				FTransform TransformOnSpline = StreamSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
				FVector ToSpline = TransformOnSpline.Location - ActorLocation;

				if (ToSpline.Size() > TransformOnSpline.Scale3D.Y * StreamSpline.BaseWidth)
					continue;

				Force += ToSpline.ConstrainToPlane(TransformOnSpline.Rotation.ForwardVector);
				Force += TransformOnSpline.Rotation.ForwardVector * StreamSpline.Force;
				ActiveStreamForces++;
			}
		}

		if (ActiveStreamForces > 0)
			Force /= ActiveStreamForces;

		return Force.ConstrainToPlane(FVector::UpVector);
	}	

	void AddImpulse(FVector Origin, FVector Impulse)
	{
		AccumulatedImpulse += Impulse.ConstrainToDirection(Pivot.UpVector);
		AccumulatedAngularImpulse += LinearToTorque(Origin, Impulse);
	}

	FVector ConsumeImpulse()
	{
		FVector ReturnImpulse = AccumulatedImpulse;
		AccumulatedImpulse = FVector::ZeroVector;

		return ReturnImpulse;
	}

	FVector ConsumeAngularImpulse()
	{
		FVector ReturnAngularImpulse = AccumulatedAngularImpulse;
		AccumulatedAngularImpulse = FVector::ZeroVector;

		return ReturnAngularImpulse;
	}	

	void DrawDebug()
	{
	//	Debug::DrawDebugLine(ForceAnchorComp.WorldLocation, ForceAnchorComp.WorldLocation + Force, FLinearColor::Green, 10.0, 0.0);

		for (auto ImpactingPlayer : ImpactingPlayers)
			PrintToScreen("Player " + ImpactingPlayer.Name + " on boat.", 0.0, FLinearColor::Green);	

		Debug::DrawDebugLine(Pivot.WorldLocation, Pivot.WorldLocation + AngularVelocity * 500.0, FLinearColor::Blue, 30.0, 0.0);

		TArray<UDarkPortalTargetComponent> Targets;
		GetComponentsByClass(Targets);
	
		for (auto Target : Targets)
		{
			Debug::DrawDebugPoint(Target.WorldLocation, 20.0, FLinearColor::Red, 0.0);
			Debug::DrawDebugLine(Target.WorldLocation, Target.WorldLocation + Target.UpVector * 200.0, FLinearColor::Blue, 10.0, 0.0);
		}
	}

	FVector LinearToTorque(FVector Origin, FVector LinearForce)
	{
		FVector Offset = Origin - Pivot.WorldLocation;

		FVector Torque = Offset.CrossProduct(LinearForce) / (BoatRadius * BoatRadius);

		Torque = Pivot.WorldTransform.InverseTransformVectorNoScale(Torque);

		return Torque;
	}

	UFUNCTION(BlueprintPure)
	float GetAngularSpeed() property
	{
		return AngularVelocity.Size();
	}

	UFUNCTION(BlueprintPure)
	void HasContact(bool&out ValidContact, UPhysicalMaterial&out PhysMaterial)
	{
		FMovementHitResult AnyValidContact;
		if(!MoveComp.GetAnyValidContact(AnyValidContact))
		{
			ValidContact = false;
			PhysMaterial = nullptr;
			return;
		}
		
		FHitResult HitResult = AnyValidContact.ConvertToHitResult();
		ValidContact = HitResult.IsValidBlockingHit();
		PhysMaterial = HitResult.PhysMaterial;
		return;
	}
};