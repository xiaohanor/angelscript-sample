
/**
 * Example targetable component
 *
 * Targetable components can be placed in the world with widgets and helper functions
 * for determining when the player wants to interact with something.
 *
 * Interaction components are built on top of the targetable copmonent system.
 */
class UExampleTargetableComponent : UTargetableComponent
{
	// Only one targetable can be the primary target for a particular category.
	//  Usually we categorize targetables by the button used to interact with them.
	default TargetableCategory = n"PrimaryLevelAbility";

	// Configure which players can use this targetable.
	default UsableByPlayers = EHazeSelectPlayer::Both;

	// Set the widget class from a blueprint. Widgets will be spawned for visible targetables.
	// default WidgetClass

	/**
	 * You will want to override CheckTargetable.
	 * This allows you to specify when a targetable should be visible, when it should be targetable,
	 * and to manipulate the score that determines which target is the primary.
	 *
	 * The `Targetable::` namespace contains helper functions to perform common filters.
	 */
	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		// Returning false means the targetable is not visible or usable at all
		/// This example condition means the targetable can't be used when the player is going too fast
		if (Query.Player.ActorVelocity.Size() > 100.0)
			return false;

		// The targetable widget is only visible for players within 10,000 range
		Targetable::ApplyVisibleRange(Query, 10000.0);

		// The targetable can only be targeted as primary for players within 2,000 range
		Targetable::ApplyTargetableRange(Query, 2000.0);

		// Apply scoring based on the player's camera
		//  This will make the primary target the one the player is closest to and looking at the most
		Targetable::ScoreCameraTargetingInteraction(Query);
		// If you want to ignore distance and target like an aim instead of like an interaction point, use:
		// Targetable::ScoreLookAtAim(Query);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		// Targetables can be disabled/enabled globally or for a specific player
		Disable(n"ReasonInstigator");
		DisableForPlayer(Game::Mio, Instigator = this);

		Enable(n"ReasonInstigator");
		EnableForPlayer(Game::Mio, Instigator = this);
	}
};

/**
 * Example of a capability that uses the targetable component system to select its target.
 */
class UExampleTargetableCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTargetablesComponent PlayerTargetablesComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		// Use the player targetables component to interact with targetables
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsBlocked() && !IsActive())
		{
			// If it's possible to use a targetable, show widgets for them.
			//  This will show widgets for any targetables of the specified class
			//  that are visible according to its CheckTargetable, this frame.
			PlayerTargetablesComponent.ShowWidgetsForTargetables(UExampleTargetableComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FExampleTargetableCapabilityParams& Params) const
	{
		// When we press right trigger, we try to interact with the primary target
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		// Retrieve the primary targetable component, determined by the scoring in CheckTargetable
		//  Will return null if there is no primary target, or if the primary target is a
		//  different type of component than the one we specify.
		auto PrimaryTarget = PlayerTargetablesComponent.GetPrimaryTarget(UExampleTargetableComponent);
		if (PrimaryTarget == nullptr)
			return false;

		// Set a parameter for the target we're interacting with so we can use it in OnActivated
		Params.ActivatedTargetable = PrimaryTarget;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FExampleTargetableCapabilityParams Params)
	{
		Print("Interacted with example targetable: "+Params.ActivatedTargetable);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};

struct FExampleTargetableCapabilityParams
{
	UExampleTargetableComponent ActivatedTargetable;
};