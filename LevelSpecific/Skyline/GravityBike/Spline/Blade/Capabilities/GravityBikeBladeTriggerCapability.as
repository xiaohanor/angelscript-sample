struct FGravityBikeBladeTriggerActivateParams
{
	AGravityBikeBladeGravityTrigger Trigger;
}

class UGravityBikeBladeTriggerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeBlade::Tags::GravityBikeBlade);
	default CapabilityTags.Add(GravityBikeBlade::Tags::GravityBikeBladeTrigger);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 100;

	AGravityBikeSpline GravityBike;

	AHazePlayerCharacter Player;
	UGravityBikeBladePlayerComponent BladeComp;
	UHazeUserWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);

		Player = GravityBikeBlade::GetPlayer();
		BladeComp = UGravityBikeBladePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeBladeTriggerActivateParams& Params) const
	{
		if(BladeComp.GravityTriggers.Num() == 0)
			return false;

		if(BladeComp.IsThrowingOrThrown())
			return false;

		if(BladeComp.IsGrappling())
			return false;

        AGravityBikeBladeGravityTrigger Trigger = GetPrimaryTrigger();

		if(Trigger == nullptr)
			return false;

		Params.Trigger = Trigger;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
        if(BladeComp.GravityTriggers.Num() == 0)
			return true;

		if(BladeComp.IsThrowingOrThrown())
			return true;

		if(BladeComp.IsGrappling())
			return true;

        AGravityBikeBladeGravityTrigger Trigger = GetPrimaryTrigger();

		if(Trigger == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeBladeTriggerActivateParams Params)
	{
        BladeComp.SetPrimaryGravityTrigger(Params.Trigger);
		UGravityBikeBladeEventHandler::Trigger_OnGravityTriggerEntered(Player);

		Widget = Player.AddWidget(BladeComp.TargetWidgetClass);

		TimeDilation::StartWorldTimeDilationEffect(BladeComp.GetPrimaryGravityTrigger().TimeDilationEffect, this);
	}

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        BladeComp.SetPrimaryGravityTrigger(nullptr);
		UGravityBikeBladeEventHandler::Trigger_OnGravityTriggerExited(Player);

		TimeDilation::StopWorldTimeDilationEffect(this);

		Player.RemoveWidget(Widget);
		Widget = nullptr;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(HasControl())
		{
			AGravityBikeBladeGravityTrigger PrimaryGravityTrigger = GetPrimaryTrigger();

			if(PrimaryGravityTrigger != BladeComp.GetPrimaryGravityTrigger())
				BladeComp.CrumbSetPrimaryGravityTrigger(PrimaryGravityTrigger);
		}

		if(BladeComp.GetPrimaryGravityTrigger().TargetComp != nullptr)
		{
			Widget.SetVisibility(ESlateVisibility::Visible);

			// FVector LineStart = Player.ActorLocation;
			// FVector LineEnd = Player.ActorLocation + Player.ViewRotation.ForwardVector * 10000; 		
			// FVector TargetLocation = BladeComp.GetPrimaryGravityTrigger().GravitySurface.GetClosestPointToLine(LineStart, LineEnd);

			const FVector TargetLocation = BladeComp.GetPrimaryGravityTrigger().TargetComp.GetVisualLocation();

			Widget.SetWidgetWorldPosition(TargetLocation);
		}
		else
		{
			Widget.SetVisibility(ESlateVisibility::Hidden);
		}
    }

    AGravityBikeBladeGravityTrigger GetPrimaryTrigger() const
    {
        if(BladeComp.GravityTriggers.Num() == 0)
            return nullptr;

        float ClosestDistance = BIG_NUMBER;
        AGravityBikeBladeGravityTrigger ClosestTrigger = nullptr;

        for(auto& Trigger : BladeComp.GravityTriggers)
        {
            if(Trigger.IsCurrentGravitySpline())
                continue;

            float Distance = Trigger.ActorLocation.Distance(Owner.ActorLocation);
            if(Distance < ClosestDistance)
            {
                ClosestDistance = Distance;
                ClosestTrigger = Trigger;
            }
        }

        return ClosestTrigger;
    }
}