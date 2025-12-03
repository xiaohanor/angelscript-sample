class UTeenDragonTailGeckoClimbEdgeJumpingVolumeComponent : USceneComponent
{

}

class ATeenDragonTailGeckoClimbEdgeJumpingVolume : AVolume
{
	default Shape::SetVolumeBrushColor(this, FLinearColor::Green);
	default ActorScale3D = FVector(5, 5, 5);
	default BrushComponent.LineThickness = 10;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailGeckoClimbEdgeJumpingVolumeComponent LineRoot;

	UPROPERTY(DefaultComponent, Attach = LineRoot)
	USceneComponent LandingLineFirstPoint;

	UPROPERTY(DefaultComponent, Attach = LineRoot)
	USceneComponent LandingLineSecondPoint;

	// How far away from the edge the dragon should land
	UPROPERTY(EditAnywhere, Category = "Settings")
	float EdgeLandingDistance = 400;

	// The shortest jump it can make
	UPROPERTY(EditAnywhere, Category = "Settings")
	float EdgeJumpMinDistance = 600;

	// The shortest jump it can make
	UPROPERTY(EditAnywhere, Category = "Settings")
	float EdgeJumpMaxDistance = 1000;

	// How much of the velocity remains after landing (so you don't slide off the surface) make 1.0 on places you want it to slide off, such as places where you can ledge up 
	UPROPERTY(EditAnywhere, Category = "Settings")
	float LandingVelocityMultiplier = 0.1;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		auto DragonComp = UPlayerTeenDragonComponent::Get(Player);
		if(DragonComp == nullptr)
			return;	
		UTeenDragonTailGeckoClimbComponent GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		if(GeckoClimbComp == nullptr)
			return;

		GeckoClimbComp.EdgeJumpingVolumes.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		auto DragonComp = UPlayerTeenDragonComponent::Get(Player);
		if(DragonComp == nullptr)
			return;	
		UTeenDragonTailGeckoClimbComponent GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		if(GeckoClimbComp == nullptr)
			return;

		GeckoClimbComp.EdgeJumpingVolumes.RemoveSingleSwap(this);
	}
}

#if EDITOR
class UTeenDragonTailGeckoClimbLandingLineVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTeenDragonTailGeckoClimbEdgeJumpingVolumeComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UTeenDragonTailGeckoClimbEdgeJumpingVolumeComponent>(Component);
		auto Volume = Cast<ATeenDragonTailGeckoClimbEdgeJumpingVolume>(Comp.Owner);

		if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		SetRenderForeground(false);

		DrawLine(Volume.LandingLineFirstPoint.WorldLocation, 
			Volume.LandingLineSecondPoint.WorldLocation,FLinearColor::Green, 20);

		FVector MinJumpFirstPoint = Volume.LandingLineFirstPoint.WorldLocation - Volume.LineRoot.UpVector * Volume.EdgeJumpMinDistance;
		FVector MinJumpSecondPoint = Volume.LandingLineSecondPoint.WorldLocation - Volume.LineRoot.UpVector * Volume.EdgeJumpMinDistance;

		DrawDashedLine(MinJumpFirstPoint, MinJumpSecondPoint, FLinearColor::Red, 10, 10, false, 80);

		FVector MaxJumpFirstPoint = Volume.LandingLineFirstPoint.WorldLocation - Volume.LineRoot.UpVector * Volume.EdgeJumpMaxDistance;
		FVector MaxJumpSecondPoint = Volume.LandingLineSecondPoint.WorldLocation - Volume.LineRoot.UpVector * Volume.EdgeJumpMaxDistance;

		DrawDashedLine(MaxJumpFirstPoint, MaxJumpSecondPoint, FLinearColor::Yellow, 10, 10, false, 80);

		FVector LandingAreaFirstPoint = Volume.LandingLineFirstPoint.WorldLocation - Volume.LineRoot.UpVector * Volume.EdgeLandingDistance;
		FVector LandingAreaSecondPoint = Volume.LandingLineSecondPoint.WorldLocation - Volume.LineRoot.UpVector * Volume.EdgeLandingDistance;

		DrawDashedLine(LandingAreaFirstPoint, LandingAreaSecondPoint, FLinearColor::Black, 10, 10, false, 80);
	}
}
#endif