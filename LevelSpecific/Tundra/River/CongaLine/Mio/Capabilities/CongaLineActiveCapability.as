struct FCongaLineActiveDeactivateParams
{
	bool bSwitchedOutOfMonkeyForm = false;
}

/**
 * This capability is active while the conga line system is active, and we are snow monkey.
 * It handles enabling the CongaLine_Active sheet, and dispersing all monkeys if we switch out of snow monkey form.
 */
class UCongaLineActiveCapability : UHazePlayerCapability
{
	//default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CongaLine::Tags::CongaLine);

	default TickGroup = EHazeTickGroup::Input;

	UCongaLinePlayerComponent CongaComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CongaComp = UCongaLinePlayerComponent::Get(Player);
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CongaLine::GetManager().IsActive())
			return false;

		// if(ShapeshiftingComp.GetCurrentShapeType() != ETundraShapeshiftShape::Big)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FCongaLineActiveDeactivateParams& Params) const
	{
		if(!CongaLine::GetManager().IsActive())
			return true;

		if(ShapeshiftingComp.GetCurrentShapeType() != ETundraShapeshiftShape::Big)
		{
			// We relay that the reason we deactivated was that we switched form, so that this can be processed in OnDeactivated.
			Params.bSwitchedOutOfMonkeyForm = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CongaComp.bIsLeadingCongaLine = true;

		Player.StartCapabilitySheet(CongaComp.ActiveSheet, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCongaLineActiveDeactivateParams Params)
	{
		CongaComp.bIsLeadingCongaLine = false;

		if(Params.bSwitchedOutOfMonkeyForm)
		{
			FCongaLinePLayerOnSwitchedOutOfSnowMonkeyFormEventData EventData;
			EventData.DispersedDancers = CongaComp.GetDancers();
			UCongaLinePlayerEventHandler::Trigger_OnSwitchedOutOfSnowMonkeyForm(Player, EventData);
			UCongaLinePlayerEventHandler::Trigger_OnSwitchedOutOfSnowMonkeyForm(CongaComp.GetPlayerShapeshiftActor(), EventData);

			/**
			 * NOTE: At the moment, we don't need to call CongaComp.DisperseAllDancers(), because they automatically disperse when the conga line is no longer active.
			 * It might be nice to do it here anyway, but I haven't tested it.
			 */
		}

		Player.StopCapabilitySheet(CongaComp.ActiveSheet, this);
	}
};