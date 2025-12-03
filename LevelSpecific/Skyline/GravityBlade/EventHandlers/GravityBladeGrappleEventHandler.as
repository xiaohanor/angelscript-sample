UCLASS(Abstract)
class UGravityBladeGrappleEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	UGravityBladeUserComponent BladeComp;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AGravityBladeActor GravityBlade;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBlade = Cast<AGravityBladeActor>(Owner);
		check(GravityBlade != nullptr);
		Player = Game::Mio;
		BladeComp = UGravityBladeUserComponent::Get(Player);
	}

	// Called when the blade is thrown towards a surface.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartThrow(FGravityBladeThrowData ThrowData) { }

	// Called when the gravity shift transition starts
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartGravityShiftTransition(FGravityBladeGravityTransitionData TransitionData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EndGravityShiftTransition() { }
	
	// Called when the blade has reached the surface.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EndThrow(FGravityBladeThrowData ThrowData) { }
}