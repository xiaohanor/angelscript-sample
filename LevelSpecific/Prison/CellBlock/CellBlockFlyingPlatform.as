event void FCellBlockFlyingPlatformEvent();

UCLASS(Abstract)
class ACellBlockFlyingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike FlyTimeLike;

	UPROPERTY()
	FCellBlockFlyingPlatformEvent OnReachedLocation;

	FVector FlyStartLoc;
	FVector FlyEndLoc;

	FRotator FlyStartRot;
	FRotator FlyEndRot;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			Actor.AttachToComponent(PlatformRoot, NAME_None, EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlyTimeLike.BindUpdate(this, n"UpdateFly");
		FlyTimeLike.BindFinished(this, n"FinishFly");
	}

	UFUNCTION()
	void FlyToLocation(FVector Loc, FRotator Rot)
	{
		FlyStartLoc = ActorLocation;
		FlyEndLoc = Loc;

		FlyStartRot = ActorRotation;
		FlyEndRot = Rot;

		FlyTimeLike.PlayFromStart();

		UCellBlockFlyingPlatformEffectEventHandler::Trigger_FlyUp(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateFly(float CurValue)
	{
		FVector Loc = Math::Lerp(FlyStartLoc, FlyEndLoc, CurValue);
		FRotator Rot = Math::LerpShortestPath(FlyStartRot, FlyEndRot, CurValue);
		SetActorLocation(Loc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishFly()
	{
		OnReachedLocation.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Game::GetDistanceFromLocationToClosestPlayer(ActorLocation) < 18000)
		{
			float Time = Time::GameTimeSeconds;
			float Roll = Math::DegreesToRadians(Math::Sin(Time * 1.0) * 0.8);
			float Pitch = Math::DegreesToRadians(Math::Cos(Time * 1.0) * 0.3);
			FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

			float VertOffset = Math::Sin(Time * 0.75) * 10.0;
			PlatformRoot.SetRelativeLocationAndRotation(FVector(0.0, 0.0, VertOffset), Rotation);
		}
	}

	UFUNCTION()
	void RevealLaunchPoint()
	{
		UCellBlockFlyingPlatformEffectEventHandler::Trigger_RevealLaunchPoint(this);
	}
}

class UCellBlockFlyingPlatformEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void FlyUp() {}
	UFUNCTION(BlueprintEvent)
	void RevealLaunchPoint() {}
}