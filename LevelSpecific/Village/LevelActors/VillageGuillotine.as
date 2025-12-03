UCLASS(Abstract)
class AVillageGuillotine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	USceneComponent BladeRoot;

	UPROPERTY(DefaultComponent, Attach = BladeRoot)
	UStaticMeshComponent RopeMesh;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> DropBladeCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect DropBladeFF;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DropBladeTimeLike;

	bool bBladeDropped = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DropBladeTimeLike.BindUpdate(this, n"UpdateDropBlade");
		DropBladeTimeLike.BindFinished(this, n"FinishDropBlade");
	}

	UFUNCTION()
	private void UpdateDropBlade(float CurValue)
	{
		float Height = Math::Lerp(800.0, 350.0, CurValue);
		BladeRoot.SetRelativeLocation(FVector(0.0, 0.0, Height));

		float RopeScale = Math::Lerp(1.75, 6.2, CurValue);
		RopeMesh.SetRelativeScale3D((FVector(0.1, 0.1, RopeScale)));
	}

	UFUNCTION()
	private void FinishDropBlade()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(DropBladeCamShake, this, BladeRoot.WorldLocation, 1200.0, 1800.0, 1.0, 0.5);

		ForceFeedback::PlayWorldForceFeedback(DropBladeFF, BladeRoot.WorldLocation, true, this, 1200.0, 600.0);
	}

	UFUNCTION()
	void DropBlade()
	{
		if (bBladeDropped)
			return;

		bBladeDropped = true;

		DropBladeTimeLike.PlayFromStart();

		UVillageGuillotineEffectEventHandler::Trigger_BladeDropped(this);
	}
}

class UVillageGuillotineEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void BladeDropped() {}
}