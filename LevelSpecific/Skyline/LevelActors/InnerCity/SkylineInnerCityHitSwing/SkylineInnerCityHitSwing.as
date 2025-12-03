event void FTriggersForVOHittingSwing();

namespace InnerCityHitSwing
{
	const float DelayUntilMoveAgainAfterHit = 1.5;
	const float BroomRotationSpeed = 1.5;

	const float Drag = 2.0;
	const float Restitution = 0.5;
	const float HitSpeed = 2050.0;
	const float RespawnSpeed = 2000.0;
	const float MinSpeedToBounce = 100;
	const float AngularSpeedOnHit = 200;
	const float AngularSpeedOnBounce = 50;
	const float AngularSpeedDeceleration = 1;

	const float PlayerHitStumbleMinSpeed = 200;
	const float PlayerHitStumbleIntensity = 0.2;

	const float PlayerHitKnockImpulseStrength = 2000;

	const float Gravity = 980.0;
	const float FallRespawnTime = 4.0;
};

asset SkylineInnerCityHitSwingSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineInnerCityHitSwingGroundMovementCapability);
	Capabilities.Add(USkylineInnerCityHitSwingAirMovementCapability);
	Capabilities.Add(USkylineInnerCityHitSwingRespawnCapability);
	Capabilities.Add(USkylineInnerCityHitSwingAllowIdleMovementCapability);
}

UCLASS(Abstract)
class ASkylineInnerCityHitSwing : AHazeActor
{
	access Resolver = private, USkylineInnerCityHitSwingResolver;

	UPROPERTY(DefaultComponent, RootComponent)
	UCapsuleComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent RotatingComp;

	UPROPERTY(DefaultComponent, Attach = RotatingComp)
	UStaticMeshComponent RobotBaseMesh;

	UPROPERTY(DefaultComponent, Attach = RobotBaseMesh)
	UStaticMeshComponent RobotBroomMesh;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeCombatTargetComp;
	default BladeCombatTargetComp.bCanRushTowards = false;

	UPROPERTY(DefaultComponent, Attach = BladeCombatTargetComp)
	UTargetableOutlineComponent BladeOutlineComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bCanRerunMovement = true;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FXFoam;

	UPROPERTY(DefaultComponent, Attach = FXFoam)
	UDecalTrailComponent TrailComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedYawComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeCombatResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SkylineInnerCityHitSwingSheet);

	#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
	#endif

	private float AngularSpeed;
	private float Yaw = 0;
	private uint LastStumbleFrame = 0;

	bool bFalling = false;
	float RespawningFrame = 0.0;

	UPROPERTY(EditInstanceOnly)
	ASkylineInnerCityHitSwingRespawnCloset RespawnCloset;

	UPROPERTY(Transient)
	USwingPointComponent SwingPoint = nullptr;

	UPROPERTY(EditInstanceOnly)
	ASplineActor StartMoveSpline;
	UPROPERTY(EditInstanceOnly)
	ASplineActor IdleMoveSpline1;
	UPROPERTY(EditInstanceOnly)
	ASplineActor IdleMoveSpline2;
	float LastHitTime = 0.0;
	bool bAllowIdleMovement = true;
	bool bZoeAttached = false;

	float SpongeRotationTimer = 0.0; 
	UPROPERTY(BlueprintReadOnly)
	FHazeAcceleratedFloat SpongeRotSpeed;

	UPROPERTY()
	FTriggersForVOHittingSwing OnHitAndZoeIsAttached;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		SwingPoint = USwingPointComponent::Get(this);

		BladeCombatResponseComp.OnHit.AddUFunction(this, n"HandleHit");

		MoveComp.Reset(true, ActorUpVector, true, 100);
		MoveComp.SnapToGround(false);

		SwingPoint.OnPlayerAttachedEvent.AddUFunction(this, n"HandleSwingAttached");
		SwingPoint.OnPlayerDetachedEvent.AddUFunction(this, n"HandleSwingDetached");

		UMovementStandardSettings::SetWalkableSlopeAngle(this, 20, this);
		UMovementGravitySettings::SetGravityAmount(this, InnerCityHitSwing::Gravity, this);
	}
	
	bool HasBeenHit() const
	{
		return LastHitTime > KINDA_SMALL_NUMBER;
	}

	bool JustRespawned() const
	{
		return Time::GameTimeSeconds - RespawningFrame < 1.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TickRotation(DeltaSeconds);
	}


	private void TickRotation(float DeltaSeconds)
	{
		if(HasControl())
		{
			// Calculate the current rotation from the angular speed, and apply it to the component
			AngularSpeed = Math::FInterpTo(AngularSpeed, 0, DeltaSeconds, InnerCityHitSwing::AngularSpeedDeceleration);
			Yaw += AngularSpeed * DeltaSeconds;
			SyncedYawComp.SetValue(Yaw);
		}
		RotatingComp.SetRelativeRotation(FRotator(0, SyncedYawComp.Value, 0));

		const float WholeRotationDuration = InnerCityHitSwing::DelayUntilMoveAgainAfterHit;
		float RotationSpeed = InnerCityHitSwing::BroomRotationSpeed;
		if (LastHitTime + InnerCityHitSwing::DelayUntilMoveAgainAfterHit > Time::GameTimeSeconds)
			RotationSpeed = 0.0;
		SpongeRotSpeed.AccelerateTo(RotationSpeed, 3.0 , DeltaSeconds);
		SpongeRotationTimer = Math::Wrap(SpongeRotationTimer + DeltaSeconds * SpongeRotSpeed.Value, 0.0, WholeRotationDuration);
		const float RotationYaw = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(0.0, 360.0), Math::Saturate(SpongeRotationTimer / WholeRotationDuration));
		FRotator Rotation = FRotator(0.0, RotationYaw, 0.0);
		RobotBroomMesh.SetRelativeRotation(Rotation);
	}
	
	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(!HasControl())
			return;

		LastHitTime = Time::GameTimeSeconds;

		auto Player = Cast<AHazePlayerCharacter>(CombatComp.Owner);
	
		const FVector Direction = Player.ViewRotation.ForwardVector.VectorPlaneProject(ActorUpVector);

		const FVector Impulse = Direction * InnerCityHitSwing::HitSpeed;
		MoveComp.AddPendingImpulse(Impulse);

		// Add a rotational impulse in a random direction
		const float AngularImpulse = InnerCityHitSwing::AngularSpeedOnHit * (Math::RandBool() ? 1 : -1);

		AddAngularImpulse(AngularImpulse);

		if(bZoeAttached)
		{
			Game::Zoe.PlayForceFeedback(ForceFeedback, false, false, this, 1.0);
			OnHitAndZoeIsAttached.Broadcast();
		}
	}

	UFUNCTION()
	private void HandleSwingAttached(AHazePlayerCharacter Player, USwingPointComponent Swing)
	{
		if(Player == Game::Zoe)
			bZoeAttached = true;
	}

	UFUNCTION()
	private void HandleSwingDetached(AHazePlayerCharacter Player, USwingPointComponent Swing)
	{
		if(Player == Game::Zoe)
			bZoeAttached = false;
	}

	private void AddAngularImpulse(float AngularImpulse)
	{
#if EDITOR
		TEMPORAL_LOG(this).Event(f"Add Angular Impulse: {AngularImpulse}");
#endif

		AngularSpeed += AngularImpulse;
	}

	access:Resolver
	void OnBounce(FSkylineInnerCityHitSwingBounce Bounce)
	{
		if(!HasControl())
			return;

		if(LastStumbleFrame < Time::FrameNumber)
			StumbleIfHitMio(Bounce);

		// Calculate the direction we were moving for this bounce
		const FVector HitDelta = Bounce.HitResult.TraceEnd - Bounce.HitResult.TraceStart;

		// Calculate which side we hit the wall on
		const FVector HitRightVector = HitDelta.CrossProduct(MoveComp.WorldUp);
		const bool bHitOnLeftSide = HitRightVector.DotProduct(Bounce.HitResult.Normal) < 0;

		// Project our velocity along the wall, meaning we get a longer vector the more aligned we are with the wall
		const FVector VelocityAlongWall = Bounce.Velocity.VectorPlaneProject(Bounce.HitResult.Normal);

		// Calculate the angular impulse based on the velocity along the wall
		float AngularImpulse = VelocityAlongWall.Size() * (0.005 * InnerCityHitSwing::AngularSpeedOnBounce);

		// Flip the angular impulse based on which side the hit was on, then apply it to the actor
		AngularImpulse *= (bHitOnLeftSide ? -1 : 1);

		AddAngularImpulse(AngularImpulse);
	}

	private void StumbleIfHitMio(FSkylineInnerCityHitSwingBounce Bounce)
	{
		check(HasControl());

		auto HitPlayer = Cast<AHazePlayerCharacter>(Bounce.HitResult.Actor);
		if(HitPlayer == nullptr)
			return;

		// Zoe should never be hit, and if she is, it would be weird to stumble her since she can't have the same gravity
		if(!HitPlayer.IsMio())
			return;

		// Mio has a different world up, don't stumble
		if(HitPlayer.MovementWorldUp.DotProduct(MoveComp.WorldUp) < 0.9)
			return;

		const float BounceSpeed = Math::Abs(Bounce.Velocity.DotProduct(Bounce.ReflectNormal));
		if(BounceSpeed < InnerCityHitSwing::PlayerHitStumbleMinSpeed)
			return;

		LastStumbleFrame = Time::FrameNumber;
		if (JustRespawned()) // knock instead
		{
			FVector KnockImpulse = -Bounce.ReflectNormal * InnerCityHitSwing::PlayerHitKnockImpulseStrength;
			CrumbKnockPlayer(HitPlayer, KnockImpulse);
		}
		else
		{
			const float BounceIntensity = BounceSpeed * InnerCityHitSwing::PlayerHitStumbleIntensity;
			FVector StumbleImpulse = -Bounce.ReflectNormal * BounceIntensity;
			CrumbStumblePlayer(HitPlayer, StumbleImpulse);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStumblePlayer(AHazePlayerCharacter Player, FVector StumbleImpulse)
	{
		Player.ApplyStumble(StumbleImpulse);
		USkylineInnerCityHitSwingEventHandler::Trigger_OnBounceAgainstPlayer(this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbKnockPlayer(AHazePlayerCharacter Player, FVector KnockImpulse)
	{
		Player.ApplyKnockdown(KnockImpulse, 2.0);
		USkylineInnerCityHitSwingEventHandler::Trigger_OnBounceAgainstPlayer(this);
	}
	
	UFUNCTION()
	void DisableVFX()
	{
		FXFoam.Deactivate();
	}

	UFUNCTION()
	void EnableVFX()
	{
		FXFoam.ResetSystem();
		FXFoam.Activate();
	}

	void DisableSwingPoint()
	{
		SwingPoint.Disable(this);
	}

	void EnableSwingPoint()
	{
		SwingPoint.Enable(this);
	}
};