UCLASS(Abstract)
class AVillageOgreTiltPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UFauxPhysicsConeRotateComponent WobbleRoot;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TiltTimeLike;

	UPROPERTY(EditInstanceOnly)
	bool bPreviewTilt = false;

	bool bTilted = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewTilt)
			SetActorRotation(FRotator(-15.0, ActorRotation.Yaw, 0.0));
		else
			SetActorRotation(FRotator(0.0, ActorRotation.Yaw, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TiltTimeLike.BindUpdate(this, n"UpdateTilt");
		TiltTimeLike.BindFinished(this, n"FinishTilt");

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			Actor.GetRootComponent().SetMobility(EComponentMobility::Movable);
			Actor.AttachToComponent(PlatformRoot, NAME_None, EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION()
	void Tilt()
	{
		if (bTilted)
			return;

		bTilted = true;
		TiltTimeLike.PlayFromStart();

		UVillageOgreTiltPlatformEffectEventHandler::Trigger_Tilt(this);
	}

	UFUNCTION()
	private void UpdateTilt(float CurValue)
	{
		float Rot = Math::Lerp(0.0, -15.0, CurValue);
		PlatformRoot.SetRelativeRotation(FRotator(Rot, 0.0, 0.0));
	}

	UFUNCTION()
	private void FinishTilt()
	{
	}
}

class UVillageOgreTiltPlatformEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Tilt() {}
}