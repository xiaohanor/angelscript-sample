
class UBattlefieldHoverboardGrappleComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	AGrappleHook Grapple;
	UHazeMovementComponent MoveComp;
	UBattlefieldHoverboardGrappleSettings Settings;

	float GrappleHeightOffset;
	float DistToTarget;

	FPlayerGrappleData Data;
	FPlayerGrappleAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		Settings = UBattlefieldHoverboardGrappleSettings::GetSettings(Player);

		Grapple = SpawnActor(Settings.HookClass);
		Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
		Grapple.UsingPlayer = Player;
		Grapple.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetHeightAndAngleDiff();
	}

	void SetHeightAndAngleDiff()
	{
		if(Data.CurrentGrapplePoint == nullptr)
			return; 
		
		FVector Direction = Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation;
		DistToTarget = Direction.Size();
		FVector Diff = Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation;
		FVector ConstrainedDiff = Diff.ConstrainToDirection(MoveComp.WorldUp);
		AnimData.HeightDiff = ConstrainedDiff.Size() * (Math::Sign(MoveComp.WorldUp.DotProduct(ConstrainedDiff)));

		FVector FlattenedDirection = Direction.ConstrainToPlane(MoveComp.WorldUp);
		AnimData.AngleDiff = Math::Atan2(FlattenedDirection.DotProduct(Player.ActorRightVector), FlattenedDirection.DotProduct(Player.ActorForwardVector));
		AnimData.AngleDiff = Math::RadiansToDegrees(AnimData.AngleDiff);
	}

	void CalculateHeightOffset()
	{
		FVector Diff = Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation;
		// FVector2D Input = FVector2D(500.0, 1250.0);
		FVector2D Input = FVector2D(150.0, 1250.0);
		// FVector2D Output = FVector2D(450.0, 800.0);
		FVector2D Output = FVector2D(50.0, 800.0);
		FVector ConstrainedDiff = Diff.ConstrainToDirection(MoveComp.WorldUp);
		float NewHeightOffset = Math::GetMappedRangeValueClamped(Input, Output, ConstrainedDiff.Size() * (Math::Sign(MoveComp.WorldUp.DotProduct(ConstrainedDiff))));
		GrappleHeightOffset = NewHeightOffset;
	}
}