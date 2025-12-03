UCLASS(NotBlueprintable)
class UGravityBikeWheelComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	float Radius = 40;

	UPROPERTY(EditAnywhere)
	float Depth = 20;

	FVector RelativeToActorLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RelativeToActorLocation = Owner.ActorTransform.InverseTransformPosition(WorldLocation);
	}
};

class UGravityBikeWheelComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeWheelComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto WheelComp = Cast<UGravityBikeWheelComponent>(Component);
		if(WheelComp == nullptr)
			return;

		//DrawWireSphere(WheelComp.GetTopLocation(), WheelComp.Radius, FLinearColor::Green, 0.2, 32);
		DrawWireSphere(WheelComp.GetWorldLocation(), WheelComp.Radius, FLinearColor::Yellow, 0.2, 32);
		//DrawWireSphere(WheelComp.GetBottomLocation(), WheelComp.Radius, FLinearColor::Red, 0.2, 32);
	}
};