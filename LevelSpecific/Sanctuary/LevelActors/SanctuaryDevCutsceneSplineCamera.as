class ASanctuaryDevCutsceneSplineCamera : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly)
	AStaticCameraActor CameraActor;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPoint;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAlongSplineTimeLike;
	default MoveAlongSplineTimeLike.UseLinearCurveZeroToOne();

	AHazePlayerCharacter PlayerCharacter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveAlongSplineTimeLike.BindUpdate(this, n"MoveAlongSplineTimeLikeUpdate");
		MoveAlongSplineTimeLike.BindFinished(this, n"MoveAlongSplineTimeLikeFinished");
	}

	UFUNCTION()
	private void MoveAlongSplineTimeLikeUpdate(float CurrentValue)
	{
		CameraActor.SetActorLocationAndRotation(SplineComp.GetWorldLocationAtSplineFraction(CurrentValue), SplineComp.GetWorldRotationAtSplineFraction(CurrentValue));
	}

	UFUNCTION()
	private void MoveAlongSplineTimeLikeFinished()
	{
		PlayerCharacter.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Normal);
		PlayerCharacter.DeactivateCameraByInstigator(this, 4.0);

		for (auto P : Game::GetPlayers())
		{
			P.UnblockCapabilities(n"Movement", this);
		}
	}

	UFUNCTION()
	void StartCutscene(AHazePlayerCharacter Player, bool bBackwards = false)
	{
		PlayerCharacter = Player;

		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		Player.ActivateCamera(CameraActor, 0.0, this, EHazeCameraPriority::Cutscene);

		for (auto P : Game::GetPlayers())
		{
			P.TeleportToRespawnPoint(RespawnPoint, this);
			P.BlockCapabilities(n"Movement", this);
		}

		if (!bBackwards)
			MoveAlongSplineTimeLike.PlayFromStart();
		else	
			MoveAlongSplineTimeLike.ReverseFromEnd();
	}
};