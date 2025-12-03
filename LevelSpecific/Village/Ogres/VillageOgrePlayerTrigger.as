class AVillageOgrePlayerTrigger : APlayerTrigger
{
	default BrushColor = FLinearColor(1.00, 0.00, 0.87);
	default BrushComponent.LineThickness = 2.0;

	UPROPERTY(EditAnywhere)
	bool bTriggerOnce = true;
	bool bTriggered = false;

	UPROPERTY(EditAnywhere)
	TArray<AVillageOgreBase> Ogres;

	UPROPERTY(EditAnywhere)
	EVillageOgreTriggerBehavior Behavior = EVillageOgreTriggerBehavior::Rush;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (bTriggerOnce && bTriggered)
			return;

		bTriggered = true;

		for (AVillageOgreBase Ogre : Ogres)
		{
			if (Behavior == EVillageOgreTriggerBehavior::Rush)
				Ogre.Rush();
			else if (Behavior == EVillageOgreTriggerBehavior::Chase)
				Ogre.StartChasing();
			else if (Behavior == EVillageOgreTriggerBehavior::Jump)
				Ogre.Jump();
			else if (Behavior == EVillageOgreTriggerBehavior::Run)
				Ogre.Run();
		}
	}
}

enum EVillageOgreTriggerBehavior
{
	None,
	Rush,
	Chase,
	Jump,
	Run
}