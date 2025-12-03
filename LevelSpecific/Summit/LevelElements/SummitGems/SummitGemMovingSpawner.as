event void FSummitGemMovingSpawnerSignature();

class ASummitGemMovingSpawner : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FirstPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SecondEndPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ThirdEndPosition;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	bool bAutoPlay;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 5.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(5.0, 1.0);

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;
	FTransform SecondEndingTransform;
	FQuat SecondEndingRotation;
	FVector SecondEndingPosition;
	FTransform ThirdEndingTransform;
	FQuat ThirdEndingRotation;
	FVector ThirdEndingPosition;

	UPROPERTY()
	FSummitGemMovingSpawnerSignature OnReachedFirstDestination;

	UPROPERTY()
	FSummitGemMovingSpawnerSignature OnReachedSecondDestination;

	UPROPERTY()
	FSummitGemMovingSpawnerSignature OnEnemiesDefeated;

	bool bReachedFirstDestination;
	bool bReachedSceondDestination;
	bool bIsPlaying;
	bool bEnemiesDefeated;
	
	UPROPERTY(EditAnywhere)
	UNiagaraSystem SmashDownEffect;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	ASummitNightQueenGem Gem;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableObject.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = FirstPosition.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		SecondEndingTransform = SecondEndPosition.GetWorldTransform();
		SecondEndingPosition = SecondEndingTransform.GetLocation();
		SecondEndingRotation = SecondEndingTransform.GetRotation();

		ThirdEndingTransform = ThirdEndPosition.GetWorldTransform();
		ThirdEndingPosition = ThirdEndingTransform.GetLocation();
		ThirdEndingRotation = ThirdEndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		
		if (bAutoPlay)
			MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void Activate()
	{
		if(!bIsPlaying)
			MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		if (bEnemiesDefeated) {
			FTransform CurrentTransform = MovableObject.GetWorldTransform();
			FVector CurrentPosition = CurrentTransform.GetLocation();
			FQuat CurrentRotation = CurrentTransform.GetRotation();
			Root.SetWorldLocation(Math::Lerp(CurrentPosition, ThirdEndingPosition, Alpha));
			Root.SetWorldRotation(FQuat::SlerpFullPath(CurrentRotation, ThirdEndingRotation, Alpha));
		} else {
		
			if (bReachedSceondDestination && bReachedFirstDestination)
			{
				Root.SetWorldLocation(Math::Lerp(SecondEndingPosition, EndingPosition, Alpha));
				Root.SetWorldRotation(FQuat::SlerpFullPath(SecondEndingRotation, EndingRotation, Alpha));
			}
			else
			{
				if(!bReachedFirstDestination)
				{
					Root.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
					Root.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
				}
				else
				{
					Root.SetWorldLocation(Math::Lerp(EndingPosition, SecondEndingPosition, Alpha));
					Root.SetWorldRotation(FQuat::SlerpFullPath(EndingRotation, SecondEndingRotation, Alpha));
				}
			}
		}
	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;
		if (bEnemiesDefeated) {
			OnEnemiesDefeated.Broadcast();
			Game::Mio.PlayCameraShake(CameraShake, this, 3.0);
			Game::Zoe.PlayCameraShake(CameraShake, this, 3.0);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SmashDownEffect, ThirdEndingPosition, FRotator(0, 0, 0));
		} else {
			if(!bReachedFirstDestination)
			{
				bReachedFirstDestination = true;
				OnReachedFirstDestination.Broadcast();
				Game::Mio.PlayCameraShake(CameraShake, this, 1.0);
				Game::Zoe.PlayCameraShake(CameraShake, this, 1.0);
							Niagara::SpawnOneShotNiagaraSystemAtLocation(SmashDownEffect, ThirdEndingPosition, FRotator(0, 0, 0));

			}
			else
			{
				if(!bReachedSceondDestination)
				{
					bReachedSceondDestination = true;
					OnReachedSecondDestination.Broadcast();
				}
				else
				{
					bReachedSceondDestination = false;
				}
			}
			if (bAutoPlay)
				MoveAnimation.PlayFromStart();
		}
	}

	UFUNCTION()
	void EnemiesDefeated()
	{
		MoveAnimation.Stop();
		MoveAnimation.SetPlayRate(1.0 * 1.5);
		bEnemiesDefeated = true;
		MoveAnimation.PlayFromStart();
	}

}