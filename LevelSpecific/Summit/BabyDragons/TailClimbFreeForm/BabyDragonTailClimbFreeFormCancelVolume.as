class ABabyDragonTailClimbFreeFormCancelVolume : AVolume
{
	default Shape::SetVolumeBrushColor(this, FLinearColor::Blue);
	default ActorScale3D = FVector(5, 5, 5);
	default BrushComponent.LineThickness = 10;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(Player.IsMio())
			return;

		UPlayerTailBabyDragonComponent TailComp = UPlayerTailBabyDragonComponent::Get(Player);
		if(TailComp == nullptr)
			return;
		TailComp.bClimbCancelledExternally = true;
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(Player.IsMio())
			return;

		UPlayerTailBabyDragonComponent TailComp = UPlayerTailBabyDragonComponent::Get(Player);
		if(TailComp == nullptr)
			return;
		TailComp.bClimbCancelledExternally = false;
	}
}