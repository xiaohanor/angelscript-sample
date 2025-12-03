enum EWalkerHeadHatchInteractionState
{
	None,
	Initial,
	Grab,
	Struggle,
	Waiting,
	Opening,
	Open,
	LiftOff,
	Shooting,
	FailOpen,
	ThrownOff,
	Exiting
}

class UIslandWalkerHeadHatchInteractionComponent : UInteractionComponent
{
	default InteractionCapability = n"IslandWalkerHeadHatchInteractionCapability";

	UIslandWalkerHeadHatchInteractionComponent Other;

	// Anim when grabbing hold of hatch in preparation for struggle or open
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence GrabHatchAnim;

	// Anim while waiting for other player
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence WaitingMHAnim;

	// Anim trying to open hatch by ourselves
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence StruggleAnim;

	// Anim when opening hatch together with other player
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence OpenAnim;

	// Anim mh while not shooting into hatch
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence HoldingOpenMHAnim;

	// Anim mh while not shooting into hatch
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence ShootingMHAnim;

	// Anim when walker head lifts off due to being shot under hatch
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence LiftOffAnim;

	// Anim when players are thrown off before they shoot into hatch
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence FailOpenHatchAnim;

	// Anim when player is thrown off by flying walker head 
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence ThrowOffAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	TArray<UAnimSequence> HeadHurtShootingReactions;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	TArray<UAnimSequence> HeadHurtIdleReactions;

	UPROPERTY(EditDefaultsOnly, Category = "ButtonMash")
	TSubclassOf<UIslandWalkerHeadHatchButtonMashWidget> ButtonMashWidgetClass;

	EWalkerHeadHatchInteractionState State = EWalkerHeadHatchInteractionState::None;
};

