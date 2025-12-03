asset SkylineBossTankMortarBallSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineBossTankMortarBallMovingCapability);
	Capabilities.Add(USkylineBossTankMortarBallImpactedCapability);
};

event void FSkylineBossTankMortarBallImpactSignature(FVector Location, FVector Normal);

UCLASS(Abstract)
class ASkylineBossTankMortarBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.SphereRadius = 200.0;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent)
	USceneComponent TrailRootComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SkylineBossTankMortarBallSheet);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossTankMortarBallShockWave> ShockwaveClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossTankMortarBallFire> FireClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeUserWidget> DangerWidgetClass;
	TPerPlayer<UHazeUserWidget> DangerWidget;

	UPROPERTY(DefaultComponent)
	UTelegraphDecalComponent TargetDecal;
	default TargetDecal.SetAbsolute(true, true, true);
	default TargetDecal.Type = ETelegraphDecalType::Scifi;

	AGravityBikeFree TargetBike;
	FTraversalTrajectory LaunchTrajectory;
	UMaterialInstanceDynamic MID;

	FSkylineBossTankMortarBallImpactSignature OnMortarImpact;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
/*
		TargetDecal.SetWorldScale3D(FVector(
			1,
			(MortarBall::DamageRadius / TargetDecal.DecalSize.Y) * MortarBall::TargetDecalSize,
			(MortarBall::DamageRadius / TargetDecal.DecalSize.Z) * MortarBall::TargetDecalSize
		));

		MID = TargetDecal.CreateDynamicMaterialInstance();
*/
		auto BossTank = TListedActors<ASkylineBossTank>().Single;

		FSkylineBossTankMortarBallOnFiredEventData EventData;
		EventData.Location = ActorLocation;
		EventData.Direction = ActorVelocity.GetSafeNormal();
		USkylineBossTankMortarBallEventHandler::Trigger_OnFired(this, EventData);
		USkylineBossTankMortarBallEventHandler::Trigger_OnShotFiredFromTank(BossTank);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
			Player.RemoveWidget(DangerWidget[Player]);
	}
};