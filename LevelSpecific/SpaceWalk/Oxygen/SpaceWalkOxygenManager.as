class ASpaceWalkOxygenManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	AHazePostProcessVolume LowOxygenPostProcess; 

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (LowOxygenPostProcess != nullptr)
		{
			auto OxyComp = USpaceWalkOxygenPlayerComponent::Get(Game::Mio);
			if (OxyComp != nullptr)
			{
				LowOxygenPostProcess.BlendWeight = Math::GetMappedRangeValueClamped(
					FVector2D(0.3, 0.0),
					FVector2D(0.0, 1.0),
					OxyComp.OxygenLevel
				);

				// PrintToScreen(f"{OxyComp.OxygenLevel=}");
				// PrintToScreen(f"{LowOxygenPostProcess.BlendWeight=}");
			}
			else
			{
				LowOxygenPostProcess.BlendWeight = 0.0;
			}
		}
	}
};