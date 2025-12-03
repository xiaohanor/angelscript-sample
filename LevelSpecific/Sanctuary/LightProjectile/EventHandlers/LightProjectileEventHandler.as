UCLASS(Abstract)
class ULightProjectileEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
	UPROPERTY(BlueprintReadOnly)
	ULightProjectileUserComponent UserComp;
	UPROPERTY(BlueprintReadOnly)
	ALightProjectileActor Projectile;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Projectile = Cast<ALightProjectileActor>(Owner);
		Player = Game::Mio;
		UserComp = ULightProjectileUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hit(FLightProjectileHitData HitData) { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launch(FLightProjectileLaunchData LaunchData) { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activated() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Deactivated() { }

	UFUNCTION(BlueprintPure)
	FVector GetSpineLocation() const
	{
		const FTransform SpineTransform = UserComp.GetSpineTransform();
		return SpineTransform.Location;
	}

	UFUNCTION(BlueprintPure)
	FVector GetStartTangentLocation(float OffsetDistance = 25.0) const
	{
		const FTransform SpineTransform = UserComp.GetSpineTransform();
		const FVector Tangent = -SpineTransform.Rotation.ForwardVector * OffsetDistance;
		const FVector WorldLocation = SpineTransform.Location + Tangent;

		// Debug::DrawDebugPoint(WorldLocation, 5.0, FLinearColor::Green);

		return WorldLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetEndTangentLocation(float OffsetDistance = 25.0) const
	{
		const FTransform ActorTransform = Owner.ActorTransform;
		const FVector Tangent = -ActorTransform.Rotation.ForwardVector * OffsetDistance;
		const FVector WorldLocation = ActorTransform.Location + Tangent;

		// Debug::DrawDebugPoint(WorldLocation, 5.0, FLinearColor::Red);

		return WorldLocation;
	}
}