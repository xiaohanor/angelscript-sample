enum ERainBlockerType
{
	None,
	ForceAddRain,
	ForceRemoveRain,
};

class URainBlockerComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	ERainBlockerType RainBlockerType = ERainBlockerType::ForceRemoveRain;
};

#if EDITOR
class URainBlockerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = URainBlockerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const auto RainBlocker = Cast<URainBlockerComponent>(Component);

		if(RainBlocker == nullptr)
			return;
		
		DrawWireBox(RainBlocker.WorldLocation, RainBlocker.RelativeScale3D * FVector(1,1,0) * 100.0, RainBlocker.WorldRotation.Quaternion(), FLinearColor::LucBlue, 25);
	}
}
#endif

class ARainBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	URainBlockerComponent RainBlockerComponent;
	
	UPROPERTY(EditAnywhere)
	int Priority = 0;
		
	int opCmp(ARainBlocker Other) const
	{
		if (Priority < Other.Priority)
			return -1;
		else if (Priority > Other.Priority)
			return 1;
		else
			return 0;
	}

#if EDITOR
    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;
	default Billboard.bUseInEditorScaling = true;

#endif
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

};

