event void FPirateShipVolumeOnEnter(APirateShip Ship, APirateShipVolume Volume);
event void FPirateShipVolumeOnExit(APirateShip Ship, APirateShipVolume Volume);

UCLASS(NotBlueprintable)
class APirateShipVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	FVector Extents = FVector(1000);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "S_TriggerBox";
	default EditorIcon.WorldScale3D = FVector(20);

	UPROPERTY(DefaultComponent)
	UPirateShipVolumeComponent VolumeComp;
#endif

	UPROPERTY()
	FPirateShipVolumeOnEnter OnEnter;

	UPROPERTY()
	FPirateShipVolumeOnExit OnExit;

	private bool bShipInsideVolume = false;
	private APirateShip Ship;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Ship = Pirate::GetShip();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector RelativePoint = ActorTransform.InverseTransformPositionNoScale(Ship.ActorLocation);
		FBox Box(-Extents, Extents);
		if(!bShipInsideVolume && Box.IsInsideOrOn(RelativePoint))
		{
			bShipInsideVolume = true;
			OnEnter.Broadcast(Ship, this);
		}
		else if(bShipInsideVolume && !Box.IsInsideOrOn(RelativePoint))
		{
			bShipInsideVolume = false;
			OnExit.Broadcast(Ship, this);
		}
	}

	bool IsShipInside() const
	{
		return bShipInsideVolume;
	}
};

#if EDITOR
class UPirateShipVolumeComponent : UActorComponent
{
};

class UPirateShipVolumeComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPirateShipVolumeComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Volume = Cast<APirateShipVolume>(Component.Owner);
		if(Volume == nullptr)
			return;

		DrawSolidBox(this, Volume.ActorLocation, Volume.ActorQuat, Volume.Extents, FLinearColor::Blue, 0.2, 3);
	}
};

#endif