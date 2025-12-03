event void FVillageOgreTriggerEnterEvent(AVillageOgreBase Ogre);

class AVillageOgreTrigger : AActorTrigger
{
	default BrushColor = FLinearColor(1.00, 0.39, 0.11);
	default BrushComponent.LineThickness = 3.0;
	default ActorClasses.Add(AVillageOgreBase);

	UPROPERTY()
	FVillageOgreTriggerEnterEvent OnOgreEntered;

	UPROPERTY(EditAnywhere)
	TArray<AVillageOgreBreakable> Breakables;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditInstanceOnly)
	FVillageOgreTriggerBehavior Behavior;

	UPROPERTY(EditAnywhere)
	ALevelSequenceActor Sequence;

	bool bTriggerOnce = true;
	bool bTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OgreEntered");
	}

	UFUNCTION()
	private void OgreEntered(AHazeActor Actor)
	{
		if (bTriggerOnce && bTriggered)
			return;

		bTriggered = true;

		AVillageOgreBase Ogre = Cast<AVillageOgreBase>(Actor);
		OnOgreEntered.Broadcast(Ogre);

		for (AVillageOgreBreakable Breakable : Breakables)
		{
			Breakable.Break();
		}

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (CameraShake.IsValid())
				Player.PlayCameraShake(CameraShake, this);

			if (ForceFeedback != nullptr)
				Player.PlayForceFeedback(ForceFeedback, false, true, this);
		}
		
		if (Sequence != nullptr)
			Sequence.SequencePlayer.Play();
	}
}

struct FVillageOgreTriggerBehavior
{
	UPROPERTY()
	EVillageOgreTriggerBehavior Behavior;

	UPROPERTY()
	ASplineActor Spline;
}