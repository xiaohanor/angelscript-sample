struct FSkylineBossRocketBarrageTarget
{
	FVector Location = FVector::ZeroVector;
	bool bTargetOnGround = false;
};

UCLASS(NotBlueprintable, NotPlaceable)
class USkylineBossRocketBarrageComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossRocketBarrageProjectile> RocketClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossRocketBarrageImpact> ImpactClass;

	UPROPERTY(EditDefaultsOnly)
	int NumOfRockets = 30;

	UPROPERTY(EditDefaultsOnly)
	float LaunchInterval = 0.05;

	UPROPERTY(EditDefaultsOnly)
	float BarrageInterval = 5;

	// TODO: Make this show up more visually? Maybe match perfectly with skeletal mesh?
	UPROPERTY(EditDefaultsOnly)
	TArray<FVector> SpawnLocations;

	private ASkylineBoss Boss;
	private UHazeActorLocalSpawnPoolComponent RocketSpawnPoolComp;
	private UHazeActorLocalSpawnPoolComponent ImpactSpawnPoolComp;

	private bool bIsLaunchingRockets = false;
	float StartLaunchingTime = 0;
	AHazeActor TargetActor;
	private TArray<FVector> TargetLocations;

	private float StopLaunchingTime = 0;

	const float TargetAreaRadius = 8000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ASkylineBoss>(Owner);
		RocketSpawnPoolComp = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(RocketClass, Owner);
		ImpactSpawnPoolComp = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(ImpactClass, Owner);
	}

	bool CanSetTarget() const
	{
		if(Time::GetGameTimeSince(StopLaunchingTime) < BarrageInterval)
			return false;

		if(bIsLaunchingRockets)
			return false;

		return true;
	}

	void StartLaunching(AHazeActor InTargetActor)
	{
		if(bIsLaunchingRockets)
			StopLaunching();

		TargetActor = InTargetActor;
		TargetLocations = CalculateTargetLocations(InTargetActor.ActorLocation);

		bIsLaunchingRockets = true;
		Boss.AnimData.bFiringRockets = true;
		USkylineBossEventHandler::Trigger_RocketBarrageStartShooting(Boss);

		StartLaunchingTime = Time::GameTimeSeconds;

	}

	void StopLaunching()
	{
		if(!bIsLaunchingRockets)
			return;

		TargetActor = nullptr;
		TargetLocations.Empty();

		bIsLaunchingRockets = false;
		Boss.AnimData.bFiringRockets = false;
		USkylineBossEventHandler::Trigger_RocketBarrageStopShooting(Boss);

		StopLaunchingTime = Time::GameTimeSeconds;

	}

	bool IsLaunchingRockets() const
	{
		return bIsLaunchingRockets;
	}

	void UnspawnRockets()
	{
	}

	void LaunchRocket(FSkylineBossRocketBarrageTarget Target, int LaunchIndex)
	{
		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = GetSpawnLocation(LaunchIndex);
		SpawnParams.Rotation = WorldRotation;
		SpawnParams.Spawner = this;
		auto Rocket = Cast<ASkylineBossRocketBarrageProjectile>(RocketSpawnPoolComp.Spawn(SpawnParams));
		
		Rocket.RocketBarrageComp = this;
		Rocket.ActorsToIgnore.Add(Owner);
		Rocket.Target = Target;
		
//		const FVector LaunchDirection = Math::GetRandomConeDirection(ForwardVector, Math::DegreesToRadians(60.0), Math::DegreesToRadians(40.0));
		const FVector LaunchDirection = Math::GetRandomHalfConeDirection(ForwardVector, UpVector, Math::DegreesToRadians(50.0), Math::DegreesToRadians(30.0));
//		const FVector LaunchDirection = ForwardVector;

		Rocket.SetActorVelocity(LaunchDirection * 16000.0);

		Rocket.TargetDecal.SetWorldLocationAndRotation(Target.Location, FRotator::MakeFromX(FVector::UpVector));
	}

	TArray<FVector> CalculateTargetLocations(FVector Origin) const
	{
		TArray<FVector> Locations;

		for (int i = 0; i < NumOfRockets; i++)
		{	
			Locations.Add(Origin + Math::GetRandomPointInCircle_XY() * TargetAreaRadius);
		}

		return Locations;
	}

	FSkylineBossRocketBarrageTarget GetRocketBarrageTarget(FVector Origin) const
	{
		FSkylineBossRocketBarrageTarget Target;

		Target.Location = (Origin + Math::GetRandomPointInCircle_XY() * TargetAreaRadius);
	
		auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		FVector Start = Target.Location + (FVector::UpVector * 1000.0);
		FVector End = Start - (FVector::UpVector * 20000.0);

		auto HitResult = Trace.QueryTraceSingle(Start, End);
		if (HitResult.bBlockingHit)
		{
			Target.Location = HitResult.Location;
			Target.bTargetOnGround = true;
		}

		return Target;
	}

	FVector GetSpawnLocation(int RocketIndex) const
	{
		if(SpawnLocations.IsEmpty())
			return WorldLocation;

		int LocationIndex = RocketIndex % SpawnLocations.Num();
		return WorldTransform.TransformPositionNoScale(SpawnLocations[LocationIndex]);
	}

	ASkylineBossRocketBarrageImpact SpawnRocketImpact(FVector Location, FRotator Rotation)
	{
		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = Location;
		SpawnParams.Rotation = Rotation;
		SpawnParams.Spawner = this;
		auto Impact = Cast<ASkylineBossRocketBarrageImpact>(ImpactSpawnPoolComp.Spawn(SpawnParams));
		return Impact;
	}
};

namespace SkylineBoss
{
	UFUNCTION(BlueprintCallable, Category = "Tripod Boss")
	void LaunchRocketBarrage(AHazeActor Target)
	{
		auto Boss = ASkylineBoss::Get();
		auto RocketBarrage = USkylineBossRocketBarrageComponent::Get(Boss);
		RocketBarrage.StartLaunching(Target);
	}
};

#if EDITOR
class USkylineBossRocketBarrageComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBossRocketBarrageComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto RocketBarrageComp = Cast<USkylineBossRocketBarrageComponent>(Component);
		if(RocketBarrageComp == nullptr)
			return;

		for(const FVector& RelativeLocation : RocketBarrageComp.SpawnLocations)
		{
			const FVector WorldLocation = RocketBarrageComp.WorldTransform.TransformPositionNoScale(RelativeLocation);

			DrawArrow(
				WorldLocation,
				WorldLocation + RocketBarrageComp.ForwardVector * 500,
				FLinearColor::Red,
				100,
				10,
			);
		}
	}
}
#endif