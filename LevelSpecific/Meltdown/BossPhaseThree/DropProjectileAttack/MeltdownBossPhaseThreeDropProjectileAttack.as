struct FMeltdownBossPhaseThreeDropProjectileConfig
{
	// How far in front of the player the projectile starts
	UPROPERTY()
	float ForwardOffsetFromPlayer = 2000.0;
	// How far to the right of the player the projectile starts
	UPROPERTY()
	float SidewaysOffsetFromPlayer = 300.0;
	// How far to the right of the player the projectile starts
	UPROPERTY()
	float VerticalOffsetFromPlayer = -300.0;
	// Delay until the portal opens
	UPROPERTY()
	float OpenDelay = 0.0;
	// Delay after the portal opens before the projectile launches
	UPROPERTY()
	float LaunchDelay = 1.0;
	// Horizontal speed of the projectile towards the player
	UPROPERTY()
	float HorizontalSpeed = 1000.0;
	// Gravity of the projectile
	UPROPERTY()
	float Gravity = 1500.0;
	// Maximum lifetime after firing
	UPROPERTY()
	float Lifetime = 4.0;
	// Whether to track the player or not
	UPROPERTY()
	bool bTrackPlayer = false;
	// If not tracking, randomize within this distance of the player
	UPROPERTY()
	float RandomizeTargetDistance = 1000.0;
	// If Tracking, how long after firing does it continue to track the player
	UPROPERTY()
	float TrackTimeAfterFire = 1.4;
}

class AMeltdownBossPhaseThreeDropProjectileAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;

	FHazeTimeLike OpenPortal;
	default OpenPortal.Duration = 1.0;
	default OpenPortal.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FVector StartScale = FVector(0.01);
	UPROPERTY()
	FVector EndScale = FVector(3.0);

	AHazePlayerCharacter TargetPlayer;
	FMeltdownBossPhaseThreeDropProjectileConfig Config;

	bool bPortalOpen = false;
	bool bFired = false;
	float StateTimer = 0;

	FTransform RelativeFrame;
	FVector RelativePosition;
	FVector RelativeVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		OpenPortal.BindFinished(this, n"PortalFinished");
		OpenPortal.BindUpdate(this, n"PortalUpdate");
		ProjectileRoot.SetHiddenInGame(true, true);
	}
	
	UFUNCTION()
	private void PortalUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void PortalFinished()
	{
		if (OpenPortal.IsReversed())
		{
			PortalMesh.SetHiddenInGame(true, true);
		}
		else
		{
			bPortalOpen = true;
			StateTimer = 0;
		}
	}

	void Launch(AHazePlayerCharacter Player, FMeltdownBossPhaseThreeDropProjectileConfig AttackConfig)
	{

		RemoveActorDisable(this);

		TargetPlayer = Player;
		Config = AttackConfig;
		RelativeFrame = GetTargetPlayerRelativeFrame();

		AddActorVisualsBlock(this);

		if (Config.OpenDelay > 0)
			Timer::SetTimer(this, n"StartOpening", Config.OpenDelay);
		else
			StartOpening();
	}

	UFUNCTION()
	private void StartOpening()
	{
		RemoveActorVisualsBlock(this);
		OpenPortal.PlayFromStart();
	}

	FTransform GetRandomizedPlayerRelativeFrame()
	{
		auto FlyingComp = UMeltdownBossFlyingComponent::Get(TargetPlayer);
		auto FlyingSettings = UMeltdownBossFlyingSettings::GetSettings(TargetPlayer);

		FTransform CenterTransform = FlyingComp.CenterPoint.ActorTransform;

		FVector LocalPlayerLocation = CenterTransform.InverseTransformPositionNoScale(TargetPlayer.ActorLocation);
		FVector ForwardAxis = LocalPlayerLocation.GetSafeNormal();
		FVector UpAxis = CenterTransform.InverseTransformVectorNoScale(TargetPlayer.MovementWorldUp);
		FRotator LocalRotation = FRotator::MakeFromXZ(ForwardAxis, UpAxis);

		float RandomizeAngle = Math::RadiansToDegrees(Config.RandomizeTargetDistance / FlyingComp.Distance);
		float Angle = Math::RandRange(-RandomizeAngle, RandomizeAngle);
		LocalRotation.Yaw = Math::Clamp(LocalRotation.Yaw + Angle, FlyingSettings.MinimumYaw, FlyingSettings.MaximumYaw);

		FVector TargetLocation = CenterTransform.TransformPositionNoScale(
			LocalRotation.ForwardVector * FlyingComp.Distance);

		return FTransform(
			FQuat::MakeFromZX(FVector::UpVector, (FlyingComp.CenterPoint.ActorLocation - TargetLocation)),
			TargetLocation
		);
	}

	FTransform GetTargetPlayerRelativeFrame()
	{
		auto Comp = UMeltdownBossFlyingComponent::Get(TargetPlayer);
		return FTransform(
			FQuat::MakeFromZX(FVector::UpVector, (Comp.CenterPoint.ActorLocation - TargetPlayer.ActorLocation)),
			TargetPlayer.ActorLocation
		);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bFired)
		{
			StateTimer += DeltaSeconds;
			if (StateTimer < Config.TrackTimeAfterFire && Config.bTrackPlayer)
				RelativeFrame = GetTargetPlayerRelativeFrame();

			RelativeVelocity -= FVector(0, 0, Config.Gravity) * DeltaSeconds;
			RelativePosition += (RelativeVelocity * DeltaSeconds)
				+ (FVector(0, 0, Config.Gravity) * Math::Square(DeltaSeconds) * 0.5);

			SetActorLocationAndRotation(
				RelativeFrame.TransformPosition(RelativePosition),
				FRotator::MakeFromXZ(RelativeFrame.TransformVector(RelativeVelocity), FVector::UpVector));

			if (StateTimer > Config.Lifetime)
				DestroyActor();
		}
		else
		{
			if (bPortalOpen)
			{
				StateTimer += DeltaSeconds;
				if (StateTimer >= Config.LaunchDelay)
				{
					bFired = true;
					StateTimer = 0;

					ProjectileRoot.SetHiddenInGame(false, true);

					OpenPortal.ReverseFromEnd();
					PortalMesh.DetachFromParent(true);

					if (Config.bTrackPlayer)
						RelativeFrame = GetTargetPlayerRelativeFrame();
					else
						RelativeFrame = GetRandomizedPlayerRelativeFrame();

					RelativePosition = RelativeFrame.InverseTransformPosition(ActorLocation);
					RelativeVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(
						RelativePosition, FVector::ZeroVector,
						Config.Gravity, Config.HorizontalSpeed
					);
				}
			}

			if (Config.bTrackPlayer)
				RelativeFrame = GetTargetPlayerRelativeFrame();

			FVector PortalStart = RelativeFrame.TransformPosition(
				FVector(Config.ForwardOffsetFromPlayer, Config.SidewaysOffsetFromPlayer, Config.VerticalOffsetFromPlayer)
			);

			SetActorLocationAndRotation(PortalStart, RelativeFrame.Rotator());
		}
	}
};

namespace MeltdownBossPhaseThree
{

UFUNCTION(Category = "Meltdown | Phase Three")
void SpawnMeltdownBossPhaseThreeDropProjectiles(
	AHazePlayerCharacter TargetPlayer,
	TSubclassOf<AMeltdownBossPhaseThreeDropProjectileAttack> AttackClass,
	FMeltdownBossPhaseThreeDropProjectileConfig Config,
	int ProjectileCount = 9,
	float ProjectileSpacing = 400.0,
	float ProjectileInterval = 1.0)
{
	for (int i = 0; i < ProjectileCount; ++i)
	{
		AMeltdownBossPhaseThreeDropProjectileAttack Projectile = Cast<AMeltdownBossPhaseThreeDropProjectileAttack>(
			SpawnActor(AttackClass)
		);

		FMeltdownBossPhaseThreeDropProjectileConfig ProjConfig = Config;
		ProjConfig.SidewaysOffsetFromPlayer -= ProjectileSpacing * i;
		ProjConfig.OpenDelay += ProjectileInterval * i;
		Projectile.Launch(TargetPlayer, ProjConfig);
	}
}

}