UCLASS(Abstract)
class ASplitTraversalTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PitchPivot;

	UPROPERTY(DefaultComponent, Attach = PitchPivot)
	USceneComponent MuzzleLocation;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;
	default InteractionComp.InteractionCapability = n"SplitTraversalTurretAimCapability";
	
	UPROPERTY(EditAnywhere)
	AHazeCameraActor Camera;

	UPROPERTY(EditAnywhere)
	float MinPitch = -80.0;
	UPROPERTY(EditAnywhere)
	float MaxPitch = 80.0;

	UPROPERTY(EditAnywhere)
	float PitchSpeed = 180.0;
	UPROPERTY(EditAnywhere)
	float PitchAcceleration = 180.0;
	UPROPERTY(EditAnywhere)
	float PitchDeceleration = 360.0;
	
	UPROPERTY(EditAnywhere)
	float FireCooldown = 2.0;
	UPROPERTY(EditAnywhere)
	float ProjectileScifiSpeed = 1600.0;
	UPROPERTY(EditAnywhere)
	float ProjectileScifiGravity = 980.0;
	UPROPERTY(EditAnywhere)
	float ProjectileVelocityMultiplierFantasy = 0.5;
	UPROPERTY(EditAnywhere)
	float ProjectileFantasyGravity = 980.0;
	UPROPERTY(EditAnywhere)
	bool bProjectileLosesDownwardVelocityWhenTransitioning = true;
	UPROPERTY(EditAnywhere)
	float ProjectileTargetDepth = 800.0;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASplitTraversalTurretProjectile> ProjectileClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};

class USplitTraversalTurretAimCapability : UInteractionCapability
{
	UPlayerMovementComponent MoveComp;

	ASplitTraversalTurret Turret;

	float CurrentPitch = 0.0;
	float PitchVelocity = 0.0;

	float Cooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		Turret = Cast<ASplitTraversalTurret>(ActiveInteraction.Owner);
		if (Turret.Camera != nullptr)
			Player.ActivateCamera(Turret.Camera, 2.0, this);

		PitchVelocity = 0;
		CurrentPitch = Turret.PitchPivot.RelativeRotation.Pitch;

		Player.ShowTutorialPrompt(Turret.TutorialPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (Turret != nullptr)
			Player.DeactivateCamera(Turret.Camera);

		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TiltInput = GetAttributeFloat(AttributeNames::MoveForward) - GetAttributeFloat(AttributeNames::MoveRight);
		TiltInput = Math::Clamp(TiltInput, -1, 1);

		if (Math::Abs(TiltInput) >= 0.1)
			PitchVelocity = Math::FInterpConstantTo(PitchVelocity, TiltInput * Turret.PitchSpeed, DeltaTime, Turret.PitchAcceleration);
		else
			PitchVelocity = Math::FInterpConstantTo(PitchVelocity, 0.0, DeltaTime, Turret.PitchDeceleration);

		float PrevPitch = CurrentPitch;
		CurrentPitch += PitchVelocity * DeltaTime;
		CurrentPitch = Math::Clamp(CurrentPitch, Turret.MinPitch, Turret.MaxPitch);
		PitchVelocity = (CurrentPitch - PrevPitch) / DeltaTime;

		Turret.PitchPivot.RelativeRotation = FRotator(CurrentPitch, 0, 0);

		Cooldown -= DeltaTime;
		if (WasActionStarted(ActionNames::WeaponFire) && Cooldown <= 0.0)
		{
			auto Projectile = SpawnActor(Turret.ProjectileClass, Turret.MuzzleLocation.WorldLocation, Turret.MuzzleLocation.WorldRotation);
			Projectile.Velocity = Turret.MuzzleLocation.WorldRotation.ForwardVector * Turret.ProjectileScifiSpeed;
			Projectile.ScifiGravity = Turret.ProjectileScifiGravity;
			Projectile.FantasyGravity = Turret.ProjectileFantasyGravity;
			Projectile.TargetDepth = Turret.ProjectileTargetDepth;
			Projectile.TransitionVelocityMultiplier = Turret.ProjectileVelocityMultiplierFantasy;
			Projectile.bLoseDownwardVelocityOnTransition = Turret.bProjectileLosesDownwardVelocityWhenTransitioning;
			Projectile.Turret = Turret;

			// Debug::DrawDebugLine(Turret.MuzzleLocation.WorldLocation, Turret.MuzzleLocation.WorldLocation + Turret.MuzzleLocation.WorldRotation.ForwardVector * Turret.ProjectileSpeed, Duration = 10);
			Cooldown = Turret.FireCooldown;
		}
	}
}