struct FMeltdownBossPhaseThreeHandGrabConfig
{
	// How far in front of the player the projectile starts
	UPROPERTY()
	float ForwardOffsetFromPlayer = 1000.0;
	// Delay until the portal opens
	UPROPERTY()
	float OpenDelay = 0.0;
	// Delay after the portal opens before the projectile launches
	UPROPERTY()
	float LaunchDelay = 0.5;
	// How long after firing does it continue to track the player
	UPROPERTY()
	float TrackTimeAfterFire = 0.3;
	// How long it takes to reach the player
	UPROPERTY()
	float ExtendTime = 1.0;
	// How long the hand stays at the player position before retracting
	UPROPERTY()
	float PauseTime = 0.1;
	// How long it takes to retract back to the portal
	UPROPERTY()
	float RetractTime = 0.4;
}

UCLASS(Abstract)
class AMeltdownBossPhaseHandGrabAttack : AHazeActor
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
	FVector EndScale = FVector(4.0);

	AHazePlayerCharacter TargetPlayer;
	FMeltdownBossPhaseThreeHandGrabConfig Config;

	bool bRetracted = false;
	bool bPortalOpen = false;
	bool bFired = false;
	float StateTimer = 0;

	FTransform RelativeFrame;
	FVector RelativePosition;

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
			DestroyActor();
		}
		else
		{
			ProjectileRoot.SetHiddenInGame(false, true);
			bPortalOpen = true;
			StateTimer = 0;
		}
	}

	UFUNCTION(DevFunction)
	void Launch(AHazePlayerCharacter Player, FMeltdownBossPhaseThreeHandGrabConfig AttackConfig)
	{

		RemoveActorDisable(this);

		TargetPlayer = Player;
		Config = AttackConfig;

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

	FTransform GetTargetPlayerRelativeFrame()
	{
		auto Comp = UMeltdownBossFlyingComponent::Get(TargetPlayer);
		return FTransform(
			FQuat::MakeFromXZ(Comp.CenterPoint.ActorLocation - TargetPlayer.ActorCenterLocation, FVector::UpVector),
			TargetPlayer.ActorCenterLocation
		);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bRetracted)
			return;

		if (bFired)
		{
			StateTimer += DeltaSeconds;
			if (StateTimer < Config.TrackTimeAfterFire)
				RelativeFrame = GetTargetPlayerRelativeFrame();

			float ForwardOffset = 0;
			if (StateTimer < Config.ExtendTime)
			{
				ForwardOffset = Math::Lerp(0, Config.ForwardOffsetFromPlayer, StateTimer / Config.ExtendTime);
			}
			else if (StateTimer > Config.ExtendTime + Config.PauseTime)
			{
				ForwardOffset = Math::Lerp(Config.ForwardOffsetFromPlayer, 0,
					Math::Saturate((StateTimer - Config.ExtendTime - Config.PauseTime) / Config.RetractTime));
			}
			else if (StateTimer > Config.ExtendTime)
			{
				ForwardOffset = Config.ForwardOffsetFromPlayer;
			}

			if (StateTimer > Config.ExtendTime + Config.PauseTime + Config.RetractTime)
			{
				bRetracted = true;
				ProjectileRoot.SetHiddenInGame(true, true);
				OpenPortal.ReverseFromEnd();
			}

			ProjectileRoot.RelativeLocation = FVector(ForwardOffset, 0, 0);
			DamageTrigger.RelativeLocation = FVector(ForwardOffset, 0, 0);
		}
		else
		{
			RelativeFrame = GetTargetPlayerRelativeFrame();

			if (bPortalOpen)
			{
				StateTimer += DeltaSeconds;
				if (StateTimer >= Config.LaunchDelay)
				{
					bFired = true;
					StateTimer = 0;

					RelativePosition = RelativeFrame.InverseTransformPosition(ActorLocation);
				}
			}
		}

		FVector PortalStart = RelativeFrame.TransformPosition(
			FVector(Config.ForwardOffsetFromPlayer, 0, 0)
		);
		SetActorLocationAndRotation(PortalStart,
			FRotator::MakeFromXZ(-RelativeFrame.Rotation.ForwardVector, FVector::UpVector));
	}
};

namespace MeltdownBossPhaseThree
{

UFUNCTION(Category = "Meltdown | Phase Three")
void SpawnMeltdownBossPhaseThreeHandGrabAttack(
	AHazePlayerCharacter TargetPlayer,
	TSubclassOf<AMeltdownBossPhaseHandGrabAttack> AttackClass,
	FMeltdownBossPhaseThreeHandGrabConfig Config)
{
	AMeltdownBossPhaseHandGrabAttack Projectile = Cast<AMeltdownBossPhaseHandGrabAttack>(
		SpawnActor(AttackClass)
	);

	Projectile.Launch(TargetPlayer, Config);
}

}