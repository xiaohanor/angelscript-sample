enum EAIDevMenuDamageHandling
{
	Default,
	Immortal,
	VeryHealthy
}

class UAIDevMenu : UHazeDevMenuEntryImmediateWidget
{
	AActor PrevDebugActor = nullptr; 
	UHazeTeam PrevTeam = nullptr;
	float Damage = 1.0;
	bool bBlockAllBehaviour = false;
	TArray<AHazeActor> BlockedBehaviorActors;	
	TArray<AHazeActor> BlockedMovementActors;	
	bool bPauseBehaviourMovement = false;	
	bool bPauseBehaviourAttacks = false;
	bool bPauseBehaviourFocus = false;	
	bool bPauseBehaviourPerception = false;	
	bool bSelectedMark = false;
	bool bTeamMark = false;
	bool bShowTargetsOfTeam = false;
	bool bShowTargetOfSelected = false;
	bool bShowEnemiesOfSelected = false;
	bool bShowTeamMatesOfSelected = false;

	float TeamDamage = 1.0;

	TArray<FName> DamageHandlingTypes;
	default DamageHandlingTypes.Add(n"Take damage normally");
	default DamageHandlingTypes.Add(n"Take damage but never die");
	default DamageHandlingTypes.Add(n"Massive health");

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geometry, float DeltaTime)
	{
		if (!Drawer.IsVisible())
			return;

		FHazeImmediateSectionHandle Section = Drawer.Begin();
		FHazeImmediateHorizontalBoxHandle ColumnsBox = Section.HorizontalBox();

		UBasicBehaviourComponent BehaviourComp = (DebugActor == nullptr) ? nullptr : UBasicBehaviourComponent::Get(DebugActor);
		UHazeTeam Team = (BehaviourComp != nullptr) ? BehaviourComp.Team : HazeTeam::GetTeam(AITeams::Default);
		UpdateSelectedAIEntries(ColumnsBox, BehaviourComp);
		ColumnsBox.Spacer(20);
		UpdateTeamMembersEntries(ColumnsBox, Team, BehaviourComp);

		Drawer.End();

		UpdateMark(DebugActor, PrevDebugActor, Team);
		UpdateTargetDisplay(DebugActor);
		UpdateTargetDisplayTeam(DebugActor, Team);
		PrevDebugActor = DebugActor;
		PrevTeam = Team;
	}

	void UpdateSelectedAIEntries(FHazeImmediateHorizontalBoxHandle ColumnsBox, UBasicBehaviourComponent BehaviourComp)
	{
		AHazeActor HazeDebugActor = Cast<AHazeActor>(DebugActor);
		if ((BehaviourComp == nullptr) || (HazeDebugActor == nullptr))
		{
			ColumnsBox.Text("No AI selected").Color(FLinearColor::Gray);
			return;
		}

		UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(DebugActor);

		FHazeImmediateVerticalBoxHandle SelectedAIColumn = ColumnsBox.VerticalBox();
		SelectedAIColumn.Text("Selected AI").Bold().Scale(2.0);	

		FString	AIName = "" + DebugActor.GetName();
		SelectedAIColumn.Text(AIName).Color(FLinearColor::Gray);

		// Debug drawer for Target
		UBasicAITargetingComponent TargetingComp = UBasicAITargetingComponent::Get(DebugActor);
		FHazeImmediateHorizontalBoxHandle ShowTargetBox = SelectedAIColumn.HorizontalBox();
		if (TargetingComp == nullptr || !TargetingComp.HasValidTarget())
		{
			ShowTargetBox.Text("Has no valid target");
		}
		else if (!bShowTargetOfSelected)
		{

		 	if (ShowTargetBox.Button("Show Target of AI").BackgroundColor(FLinearColor(0.1, 0.1, 0.1))) 
			{
				bShowTargetOfSelected = true;
				bShowTargetsOfTeam = false;
			}
		}
		else if (ShowTargetBox.Button("Hide Target of AI").BackgroundColor(FLinearColor(0.4, 0.4, 0.4))) 
		{
			bShowTargetOfSelected = false;
			bShowTargetsOfTeam = false;
		}

		FHazeImmediateHorizontalBoxHandle ShowSelectedBox = SelectedAIColumn.HorizontalBox();
		if (bSelectedMark)
		{
			if (ShowSelectedBox.Button("Clear mark from selected AI").BackgroundColor(FLinearColor(0.4, 0.4, 0.1)))
			{
				bSelectedMark = false;
				bTeamMark = false;
			}
		}
		else if (ShowSelectedBox.Button("Mark selected AI").BackgroundColor(FLinearColor(0.2, 0.2, 0.1))) 
		{
			bSelectedMark = true;
		}

		FHazeImmediateHorizontalBoxHandle DealDamageBox = SelectedAIColumn.HorizontalBox();
		if (DealDamageBox.Button("Deal damage to AI").BackgroundColor(FLinearColor(0.5, 0.1, 0.1)))
			DealDamage(DebugActor, Damage);
		Damage = DealDamageBox.FloatInput().Value(Damage);

		FHazeImmediateHorizontalBoxHandle DamageHandlingBox = SelectedAIColumn.HorizontalBox();
		DamageHandlingBox.Text("Damage handling").Bold();
		FHazeImmediateComboBoxHandle DamageHandlingOptions = DamageHandlingBox.ComboBox();
		DamageHandlingOptions.Items(DamageHandlingTypes);
		EAIDevMenuDamageHandling DamageHandling = GetCurrentDamageHandling(HazeDebugActor);
		DamageHandlingOptions.Value(DamageHandlingTypes[int(DamageHandling)]);
		UpdateDamageHandling(HazeDebugActor, EAIDevMenuDamageHandling(DamageHandlingOptions.SelectedIndex));

		FHazeImmediateHorizontalBoxHandle BlockAllBehaviourBox = SelectedAIColumn.HorizontalBox();
		if (BlockedBehaviorActors.Contains(HazeDebugActor))
		{
			if (BlockAllBehaviourBox.Button("Unblock all behaviour").BackgroundColor(FLinearColor(0.3, 0.1, 0.1)))
			{
				HazeDebugActor.UnblockCapabilities(BasicAITags::Behaviour, this);
				BlockedBehaviorActors.RemoveSingleSwap(HazeDebugActor);
			}			
		}
		else if (BlockAllBehaviourBox.Button("Block all behaviour").BackgroundColor(FLinearColor(0.1, 0.3, 0.1)))
		{
			HazeDebugActor.BlockCapabilities(BasicAITags::Behaviour, this);
			BlockedBehaviorActors.Add(HazeDebugActor);
		}

		UpdateBehaviourRequirementsClaim(SelectedAIColumn, BehaviourComp, EBasicBehaviourRequirement::Movement, "movement");
		UpdateBehaviourRequirementsClaim(SelectedAIColumn, BehaviourComp, EBasicBehaviourRequirement::Weapon, "attacks");
		UpdateBehaviourRequirementsClaim(SelectedAIColumn, BehaviourComp, EBasicBehaviourRequirement::Focus, "turning");
		UpdateBehaviourRequirementsClaim(SelectedAIColumn, BehaviourComp, EBasicBehaviourRequirement::Perception, "targeting");

		FHazeImmediateHorizontalBoxHandle BlockAllMovementBox = SelectedAIColumn.HorizontalBox();
		if (BlockedMovementActors.Contains(HazeDebugActor))
		{
			if (BlockAllBehaviourBox.Button("Unblock movement").BackgroundColor(FLinearColor(0.3, 0.1, 0.1)))
			{
				HazeDebugActor.UnblockCapabilities(BasicAITags::Behaviour, this);
				BlockedMovementActors.RemoveSingleSwap(HazeDebugActor);
			}			
		}
		else if (BlockAllBehaviourBox.Button("Block movement").BackgroundColor(FLinearColor(0.1, 0.3, 0.1)))
		{
			HazeDebugActor.BlockCapabilities(BasicAITags::Behaviour, this);
			BlockedMovementActors.Add(HazeDebugActor);
		}

#if EDITOR
		FHazeImmediateHorizontalBoxHandle HazeDebugBox = SelectedAIColumn.HorizontalBox();
		if (HazeDebugActor.bHazeEditorOnlyDebugBool)
			HazeDebugActor.bHazeEditorOnlyDebugBool = !HazeDebugBox.Button("Turn off main debug flag").BackgroundColor(FLinearColor(0.2, 0.1, 0.2));
		else
			HazeDebugActor.bHazeEditorOnlyDebugBool = HazeDebugBox.Button("Turn on main debug flag").BackgroundColor(FLinearColor(0.1, 0.1, 0.1));
#endif

		// Debug drawers of closest team mates
		FHazeImmediateHorizontalBoxHandle ShowClosestTeamMatesBox = SelectedAIColumn.HorizontalBox();
		if (!bShowTeamMatesOfSelected)
		{
		 	if (ShowClosestTeamMatesBox.Button("Show distance to team mates").BackgroundColor(FLinearColor(0.25, 0.25, 0.25))) 
				bShowTeamMatesOfSelected = true;
		}
		else if (ShowClosestTeamMatesBox.Button("Hide distance to team mates").BackgroundColor(FLinearColor(0.1, 0.1, 0.1))) 
		{
			bShowTeamMatesOfSelected = false;
		}

		// Debug drawers of closest targets
		FHazeImmediateHorizontalBoxHandle ShowClosestTargetsBox = SelectedAIColumn.HorizontalBox();
		if (!bShowEnemiesOfSelected)
		{
		 	if (ShowClosestTargetsBox.Button("Show distance to enemies").BackgroundColor(FLinearColor(0.25, 0.25, 0.25))) 
				bShowEnemiesOfSelected = true;
		}
		else if (ShowClosestTargetsBox.Button("Hide distance to enemies").BackgroundColor(FLinearColor(0.1, 0.1, 0.1))) 
		{
			bShowEnemiesOfSelected = false;
		}

		// Debug drawer of any active behaviours
		FHazeImmediateHorizontalBoxHandle ShowBehavioursBox = SelectedAIColumn.HorizontalBox();
		if (!DebugComp.IsDisplayingBehaviours())
		{
		 	if (ShowBehavioursBox.Button("Show active behaviours").BackgroundColor(FLinearColor(0.0, 0.2, 0.1))) 
				DebugComp.SetDebugDisplayBehaviours();
		}
		else if (ShowBehavioursBox.Button("Hide active behaviours").BackgroundColor(FLinearColor(0.1, 0.0, 0.05))) 
		{
			DebugComp.ClearDebugDisplayBehaviours();
		}

		// Debug drawer of any active capabilities
		FHazeImmediateHorizontalBoxHandle ShowCapabilitiesBox = SelectedAIColumn.HorizontalBox();
		if (!DebugComp.IsDisplayingCapabilities())
		{
		 	if (ShowCapabilitiesBox.Button("Show active capabilities").BackgroundColor(FLinearColor(0.0, 0.2, 0.1))) 
				DebugComp.SetDebugDisplayCapabilities();
		}
		else if (ShowCapabilitiesBox.Button("Hide active capabilities").BackgroundColor(FLinearColor(0.1, 0.0, 0.05))) 
		{
			DebugComp.ClearDebugDisplayCapabilities();
		}

		// Debug drawer of spawner
		FHazeImmediateHorizontalBoxHandle ShowSpawnerBox = SelectedAIColumn.HorizontalBox();
		if (!DebugComp.IsDisplayingSpawner())
		{
		 	if (ShowSpawnerBox.Button("Show spawner").BackgroundColor(FLinearColor(0.2, 0.2, 0.1))) 
				DebugComp.SetDebugDisplaySpawner();
		}
		else if (ShowSpawnerBox.Button("Hide spawner").BackgroundColor(FLinearColor(0.1, 0.1, 0.05))) 
		{
			DebugComp.ClearDebugDisplaySpawner();
		}

		// Debug drawer of control side
		FHazeImmediateHorizontalBoxHandle ShowControlSideBox = SelectedAIColumn.HorizontalBox();
		if (!DebugComp.IsDisplayingControlSide())
		{
		 	if (ShowControlSideBox.Button("Show control side").BackgroundColor(FLinearColor(0.2, 0.2, 0.1))) 
				DebugComp.SetDebugDisplayControlSide();
		}
		else if (ShowControlSideBox.Button("Hide control side").BackgroundColor(FLinearColor(0.1, 0.1, 0.05))) 
		{
			DebugComp.ClearDebugDisplayControlSide();
		}

		// Debug drawer of collision capsule
		FHazeImmediateHorizontalBoxHandle ShowCapsuleBox = SelectedAIColumn.HorizontalBox();
		if (!DebugComp.IsDisplayingCapsule())
		{
		 	if (ShowCapsuleBox.Button("Show capsule").BackgroundColor(FLinearColor(0.3, 0.3, 0.1))) 
				DebugComp.SetDebugDisplayCapsule();
		}
		else if (ShowCapsuleBox.Button("Hide capsule").BackgroundColor(FLinearColor(0.15, 0.15, 0.05))) 
		{
			DebugComp.ClearDebugDisplayCapsule();
		}

		// TODO: Need to expose functionality to set debug actor
		// SelectedAIColumn.Spacer(10);
		// FHazeImmediateHorizontalBoxHandle SelectNextAIBox = SelectedAIColumn.HorizontalBox();
		// if (SelectNextAIBox.Button("Select next AI").Padding(20, 5))
		// 	SelectNextTeamMember(HazeDebugActor, BehaviourComp);
	}

	void UpdateTeamMembersEntries(FHazeImmediateHorizontalBoxHandle ColumnsBox, UHazeTeam Team, UBasicBehaviourComponent BehaviourComp)
	{
		FHazeImmediateVerticalBoxHandle AllAIsInTeamColumn = ColumnsBox.VerticalBox();
		AllAIsInTeamColumn.Text("All AIs in team").Bold().Scale(2.0);	
		if (Team != nullptr)
			AllAIsInTeamColumn.Text("" + Team.GetName() + " (" + Team.GetMembers().Num() + " members)").Color(FLinearColor::Gray);	

		AHazeActor TeamRepresentative = Cast<AHazeActor>(DebugActor);
		if ((BehaviourComp == nullptr) && (Team != nullptr) && (Team.GetMembers().Num() > 0))
			TeamRepresentative = Team.GetMembers()[0];
		if (TeamRepresentative == nullptr)
			return;

		FHazeImmediateHorizontalBoxHandle ShowTargetBox = AllAIsInTeamColumn.HorizontalBox();
		if (!bShowTargetsOfTeam)
		{
		 	if (ShowTargetBox.Button("Show Targets of all AIs in team").BackgroundColor(FLinearColor(0.1, 0.1, 0.1))) 
			{
				bShowTargetsOfTeam = true;
				bShowTargetOfSelected = true;
			}
		}
		else if (ShowTargetBox.Button("Hide Targets of all AIs in team").BackgroundColor(FLinearColor(0.4, 0.4, 0.4))) 
		{
			bShowTargetsOfTeam = false;
			bShowTargetOfSelected = false;
		}


		FHazeImmediateHorizontalBoxHandle ShowSelectedBox = AllAIsInTeamColumn.HorizontalBox();
		if (bTeamMark)
		{
			if (ShowSelectedBox.Button("Clear mark from team members").BackgroundColor(FLinearColor(0.4, 0.4, 0.1)))
			{
				bTeamMark = false;
				bSelectedMark = false;
			}
		}
		else if (ShowSelectedBox.Button("Mark team members").BackgroundColor(FLinearColor(0.2, 0.2, 0.1))) 
		{
			bTeamMark = true;
			bSelectedMark = true;
		}

		FHazeImmediateHorizontalBoxHandle DealDamageBox = AllAIsInTeamColumn.HorizontalBox();
		if (DealDamageBox.Button("Deal damage to team").BackgroundColor(FLinearColor(0.5, 0.1, 0.1)))
			DealTeamDamage(Team, TeamDamage);
		Damage = DealDamageBox.FloatInput().Value(TeamDamage);

		FHazeImmediateHorizontalBoxHandle DamageHandlingBox = AllAIsInTeamColumn.HorizontalBox();
		DamageHandlingBox.Text("Damage handling").Bold();
		FHazeImmediateComboBoxHandle DamageHandlingOptions = DamageHandlingBox.ComboBox();
		DamageHandlingOptions.Items(DamageHandlingTypes);
		EAIDevMenuDamageHandling DamageHandling = GetCurrentDamageHandling(TeamRepresentative);
		DamageHandlingOptions.Value(DamageHandlingTypes[int(DamageHandling)]);
		if (Team != nullptr)
		{
			TArray<UAIDebugDisplayComponent> DebugComps;
			for (AHazeActor TeamMember : Team.GetMembers())
			{
				if (TeamMember == nullptr)
					continue;
				UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::Get(TeamMember);
				if (DebugComp != nullptr)
					DebugComps.Add(DebugComp);
			}

			for (AHazeActor TeamMember : Team.GetMembers())
			{
				UpdateDamageHandling(TeamMember, EAIDevMenuDamageHandling(DamageHandlingOptions.SelectedIndex));
			}
		
			FHazeImmediateHorizontalBoxHandle BlockAllBehaviourBox = AllAIsInTeamColumn.HorizontalBox();
			bool bAllBehaviourBlocked = IsAllBehaviourBlockedInTeam(Team);
			bool bAllBehaviourUnblocked = IsAllBehaviourUnblockedInTeam(Team);
			if (!bAllBehaviourBlocked)
			{
				if (BlockAllBehaviourBox.Button("Block all behaviour for team").BackgroundColor(FLinearColor((bAllBehaviourUnblocked ? 0.1 : 0.3), 0.3, 0.1)))
					BlockTeamBehaviour(Team);
			}
			if (!bAllBehaviourUnblocked)
			{
				if (BlockAllBehaviourBox.Button("Unblock all behaviour for team").BackgroundColor(FLinearColor(0.3, (bAllBehaviourBlocked ? 0.1 : 0.3), 0.1)))
					UnblockTeamBehaviour(Team);
			}

			UpdateTeamBehaviourRequirementsClaim(AllAIsInTeamColumn, Team, EBasicBehaviourRequirement::Movement, "movement for team");
			UpdateTeamBehaviourRequirementsClaim(AllAIsInTeamColumn, Team, EBasicBehaviourRequirement::Weapon, "attacks for team");
			UpdateTeamBehaviourRequirementsClaim(AllAIsInTeamColumn, Team, EBasicBehaviourRequirement::Focus, "turning for team");
			UpdateTeamBehaviourRequirementsClaim(AllAIsInTeamColumn, Team, EBasicBehaviourRequirement::Perception, "targeting for team");

			FHazeImmediateHorizontalBoxHandle BlockAllMovementBox = AllAIsInTeamColumn.HorizontalBox();
			bool bAllMovementBlocked = IsAllMovementBlockedInTeam(Team);
			bool bAllMovementUnblocked = IsAllMovementUnblockedInTeam(Team);
			if (!bAllMovementBlocked)
			{
				if (BlockAllMovementBox.Button("Block movement for team").BackgroundColor(FLinearColor((bAllMovementUnblocked ? 0.1 : 0.3), 0.3, 0.1)))
					BlockTeamMovement(Team);
			}
			if (!bAllMovementUnblocked)
			{
				if (BlockAllMovementBox.Button("Unblock movement for team").BackgroundColor(FLinearColor(0.3, (bAllMovementBlocked ? 0.1 : 0.3), 0.1)))
					UnblockTeamMovement(Team);
			}

			// Debug drawer of any active behaviours for team
			FHazeImmediateHorizontalBoxHandle ShowBehavioursBox = AllAIsInTeamColumn.HorizontalBox();
			bool bSomeWithBehavioursShown = false;
			bool bSomeWithBehavioursHidden = (DebugComps.Num() == 0);
			for (UAIDebugDisplayComponent DebugComp : DebugComps)
			{
				if (DebugComp.IsDisplayingBehaviours())
					bSomeWithBehavioursShown = true;
				else
					bSomeWithBehavioursHidden = true;	
			}
			if (bSomeWithBehavioursHidden)
			{
				FLinearColor Color = (bSomeWithBehavioursShown ? FLinearColor(0.2, 0.2, 0.1) : FLinearColor(0.0, 0.2, 0.1));
				if (ShowBehavioursBox.Button("Show active behaviours").BackgroundColor(Color)) 
				{
					for (AHazeActor TeamMember : Team.GetMembers())
					{
						if (TeamMember == nullptr)
							continue;
						UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(TeamMember);
						DebugComp.SetDebugDisplayBehaviours();					
					}
				}
			}
			else if (ShowBehavioursBox.Button("Hide active behaviours").BackgroundColor(FLinearColor(0.1, 0.0, 0.05))) 
			{
				for (UAIDebugDisplayComponent DebugComp : DebugComps)
				{
					DebugComp.ClearDebugDisplayBehaviours();
				}
			}

			// Debug drawer of any active capabilities for team
			FHazeImmediateHorizontalBoxHandle ShowCapabilitiesBox = AllAIsInTeamColumn.HorizontalBox();
			bool bSomeWithCapabilitiesShown = false;
			bool bSomeWithCapabilitiesHidden = (DebugComps.Num() == 0);
			for (UAIDebugDisplayComponent DebugComp : DebugComps)
			{
				if (DebugComp.IsDisplayingCapabilities())
					bSomeWithCapabilitiesShown = true;
				else
					bSomeWithCapabilitiesHidden = true;	
			}
			if (bSomeWithCapabilitiesHidden)
			{
				FLinearColor Color = (bSomeWithCapabilitiesShown ? FLinearColor(0.2, 0.2, 0.1) : FLinearColor(0.0, 0.2, 0.1));
				if (ShowCapabilitiesBox.Button("Show active capabilities").BackgroundColor(Color)) 
				{
					for (AHazeActor TeamMember : Team.GetMembers())
					{
						if (TeamMember == nullptr)
							continue;
						UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(TeamMember);
						DebugComp.SetDebugDisplayCapabilities();					
					}
				}
			}
			else if (ShowCapabilitiesBox.Button("Hide active capabilities").BackgroundColor(FLinearColor(0.1, 0.0, 0.05))) 
			{
				for (UAIDebugDisplayComponent DebugComp : DebugComps)
				{
					DebugComp.ClearDebugDisplayCapabilities();
				}
			}

			// Debug drawer of spawner for team
			FHazeImmediateHorizontalBoxHandle ShowSpawnerBox = AllAIsInTeamColumn.HorizontalBox();
			bool bSomeWithSpawnerShown = false;
			bool bSomeWithSpawnerHidden = (DebugComps.Num() == 0);
			for (UAIDebugDisplayComponent DebugComp : DebugComps)
			{
				if (DebugComp.IsDisplayingSpawner())
					bSomeWithSpawnerShown = true;
				else
					bSomeWithSpawnerHidden = true;	
			}
			if (bSomeWithSpawnerHidden)
			{
				FLinearColor Color = (bSomeWithSpawnerShown ? FLinearColor(0.15, 0.15, 0.1) : FLinearColor(0.2, 0.2, 0.1));
				if (ShowSpawnerBox.Button("Show spawners").BackgroundColor(Color)) 
				{
					for (AHazeActor TeamMember : Team.GetMembers())
					{
						if (TeamMember == nullptr)
							continue;
						UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(TeamMember);
						DebugComp.SetDebugDisplaySpawner();					
					}
				}
			}
			else if (ShowSpawnerBox.Button("Hide spawners").BackgroundColor(FLinearColor(0.1, 0.1, 0.05))) 
			{
				for (UAIDebugDisplayComponent DebugComp : DebugComps)
				{
					DebugComp.ClearDebugDisplaySpawner();
				}
			}

			// Debug drawer of ControlSide for team
			FHazeImmediateHorizontalBoxHandle ShowControlSideBox = AllAIsInTeamColumn.HorizontalBox();
			bool bSomeWithControlSideShown = false;
			bool bSomeWithControlSideHidden = (DebugComps.Num() == 0);
			for (UAIDebugDisplayComponent DebugComp : DebugComps)
			{
				if (DebugComp.IsDisplayingControlSide())
					bSomeWithControlSideShown = true;
				else
					bSomeWithControlSideHidden = true;	
			}
			if (bSomeWithControlSideHidden)
			{
				FLinearColor Color = (bSomeWithControlSideShown ? FLinearColor(0.15, 0.15, 0.1) : FLinearColor(0.2, 0.2, 0.1));
				if (ShowControlSideBox.Button("Show control sides").BackgroundColor(Color)) 
				{
					for (AHazeActor TeamMember : Team.GetMembers())
					{
						if (TeamMember == nullptr)
							continue;
						UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(TeamMember);
						DebugComp.SetDebugDisplayControlSide();					
					}
				}
			}
			else if (ShowControlSideBox.Button("Hide control sides").BackgroundColor(FLinearColor(0.1, 0.1, 0.05))) 
			{
				for (UAIDebugDisplayComponent DebugComp : DebugComps)
				{
					DebugComp.ClearDebugDisplayControlSide();
				}
			}

			FHazeImmediateHorizontalBoxHandle ShowCapsuleBox = AllAIsInTeamColumn.HorizontalBox();
			bool bSomeWithCapsuleShown = false;
			bool bSomeWithCapsuleHidden = (DebugComps.Num() == 0);
			for (UAIDebugDisplayComponent DebugComp : DebugComps)
			{
				if (DebugComp.IsDisplayingCapsule())
					bSomeWithCapsuleShown = true;
				else
					bSomeWithCapsuleHidden = true;	
			}
			if (bSomeWithCapsuleHidden)
			{
				FLinearColor Color = (bSomeWithCapsuleShown ? FLinearColor(0.17, 0.17, 0.1) : FLinearColor(0.3, 0.3, 0.1));
				if (ShowCapsuleBox.Button("Show capsules").BackgroundColor(Color)) 
				{
					for (AHazeActor TeamMember : Team.GetMembers())
					{
						if (TeamMember == nullptr)
							continue;
						UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(TeamMember);
						DebugComp.SetDebugDisplayCapsule();					
					}
				}
			}
			else if (ShowCapsuleBox.Button("Hide capsules").BackgroundColor(FLinearColor(0.15, 0.15, 0.05))) 
			{
				for (UAIDebugDisplayComponent DebugComp : DebugComps)
				{
					DebugComp.ClearDebugDisplayCapsule();
				}
			}
		}
	}

	bool IsMarked(AHazeActor Actor) const
	{
		UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::Get(Actor);
		if (DebugComp == nullptr)
			return false;
		return DebugComp.IsDebugSelected();
	}

	void ApplyMark(AHazeActor Actor)
	{
		bSelectedMark = true;
		if (Actor == nullptr)
			return;
		UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(Actor);
		DebugComp.SetDebugSelected();
	}

	void ClearMark(AHazeActor Actor)
	{
		bSelectedMark = false;
		bTeamMark = false;
		if (Actor == nullptr)
			return;
		UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::Get(Actor);
		if (DebugComp != nullptr)
			DebugComp.ClearDebugSelected();
	}

	void UpdateMark(AActor CurActor, AActor PrevActor, UHazeTeam Team)
	{
		if ((PrevDebugActor != CurActor) && (PrevDebugActor != nullptr) &&
			(!bTeamMark || !Team.IsMember(Cast<AHazeActor>(PrevDebugActor))))
		{
			// Clear mark from previously selected actor
			UAIDebugDisplayComponent PrevDebugComp = UAIDebugDisplayComponent::Get(PrevDebugActor);
			if (PrevDebugComp != nullptr)
				PrevDebugComp.ClearDebugSelected();
		}

		if ((PrevTeam != nullptr) && ((PrevTeam != Team) || !bTeamMark))
		{
			// Clear mark from previous team members
			for (AHazeActor TeamMember : PrevTeam.GetMembers())
			{
				UAIDebugDisplayComponent PrevDebugComp = (TeamMember != nullptr) ? UAIDebugDisplayComponent::Get(TeamMember) : nullptr;
				if (PrevDebugComp != nullptr)
					PrevDebugComp.ClearDebugSelected();
			}
		}

		if (bTeamMark && (Team != nullptr))
		{
			// Mark all AIs in team
			for (AHazeActor TeamMember : Team.GetMembers())
			{
				if ((TeamMember == nullptr) || (UBasicBehaviourComponent::Get(TeamMember) == nullptr))
					continue; // AIs only
				UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(TeamMember);
				DebugComp.SetDebugSelected();
			}
		}
		else if ((CurActor != nullptr) && (UBasicBehaviourComponent::Get(CurActor) != nullptr))
		{
			UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(CurActor);
			if (bSelectedMark)
				DebugComp.SetDebugSelected();
			else 
				DebugComp.ClearDebugSelected();
		}
	}

	void UpdateTargetDisplay(AActor CurActor)
	{
		if ((PrevDebugActor != CurActor) && (PrevDebugActor != nullptr))
		{			
			UAIDebugDisplayComponent PrevDebugComp = UAIDebugDisplayComponent::Get(PrevDebugActor);
			if (PrevDebugComp != nullptr)
			{
				PrevDebugComp.ClearDebugDisplayTarget();
				PrevDebugComp.ClearDebugDisplayEnemies();
				PrevDebugComp.ClearDebugDisplayTeamMates();
			}
		}

		if ((CurActor != nullptr) && (UBasicBehaviourComponent::Get(CurActor) != nullptr))
		{
			UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(CurActor);
			if (bShowTargetOfSelected || bShowTargetsOfTeam)
				DebugComp.SetDebugDisplayTarget();
			else
				DebugComp.ClearDebugDisplayTarget();
			
			if (bShowEnemiesOfSelected)
				DebugComp.SetDebugDisplayEnemies();
			else 
				DebugComp.ClearDebugDisplayEnemies();

			if (bShowTeamMatesOfSelected)
				DebugComp.SetDebugDisplayTeamMates();
			else 
				DebugComp.ClearDebugDisplayTeamMates();
		}
	}

	void UpdateTargetDisplayTeam(AActor CurActor, UHazeTeam Team)
	{
		// Clear previous actor
		if ((PrevDebugActor != CurActor) && (PrevDebugActor != nullptr) &&
			(!bShowTargetsOfTeam || !Team.IsMember(Cast<AHazeActor>(PrevDebugActor))))
		{			
			UAIDebugDisplayComponent PrevDebugComp = UAIDebugDisplayComponent::Get(PrevDebugActor);
			if (PrevDebugComp != nullptr)
			{
				PrevDebugComp.ClearDebugDisplayTarget();
			}
		}
	
		// Clear previous team. Or current team when toggled off.
		if ((PrevTeam != nullptr) && ((PrevTeam != Team) || !bShowTargetsOfTeam))
		{
			// Clear target display from previous team members
			for (AHazeActor TeamMember : PrevTeam.GetMembers())
			{
				// Don't clear currently selected actor
				if (TeamMember == CurActor && bShowTargetOfSelected)
					continue;

				UAIDebugDisplayComponent PrevDebugComp = (TeamMember != nullptr) ? UAIDebugDisplayComponent::Get(TeamMember) : nullptr;
				if (PrevDebugComp != nullptr)
					PrevDebugComp.ClearDebugDisplayTarget();
			}
		}

		if (bShowTargetsOfTeam && (Team != nullptr))
		{
			// Display target for all AIs in team
			for (AHazeActor TeamMember : Team.GetMembers())
			{
				if ((TeamMember == nullptr) || (UBasicBehaviourComponent::Get(TeamMember) == nullptr))
					continue; // AIs only
				UAIDebugDisplayComponent DebugComp = UAIDebugDisplayComponent::GetOrCreate(TeamMember);				
				DebugComp.SetDebugDisplayTarget();
			}
		}
	}

	void DealDamage(AActor Actor, float DamageDealt)
	{
		Damage::AITakeDamage(Actor, DamageDealt, Game::Mio, EDamageType::Default);
	}

	void DealTeamDamage(UHazeTeam Team, float DamageDealt)
	{
		for (AHazeActor TeamMember : Team.GetMembers())	
		{
			Damage::AITakeDamage(TeamMember, DamageDealt, Game::Mio, EDamageType::Default);
		}
	}

	EAIDevMenuDamageHandling GetCurrentDamageHandling(AHazeActor Actor)
	{
		if (UBasicAIHealthSettings::GetSettings(Actor).bImmortal)
			return EAIDevMenuDamageHandling::Immortal;

		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Actor);
		if ((HealthComp != nullptr) && (HealthComp.MaxHealth > 10000.0))
			return EAIDevMenuDamageHandling::VeryHealthy;

		return EAIDevMenuDamageHandling::Default;
	}

	void UpdateDamageHandling(AHazeActor Actor, EAIDevMenuDamageHandling DamageHandling)
	{
		if (Actor == nullptr)
			return;

		if (DamageHandling == EAIDevMenuDamageHandling::Immortal)
			UBasicAIHealthSettings::SetImmortal(Actor, true, this, EHazeSettingsPriority::Final);
		else
			UBasicAIHealthSettings::ClearImmortal(Actor, this, EHazeSettingsPriority::Final); // Assume we never want to turn off immortality if that was set from somewhere else

		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Actor);
		if (HealthComp != nullptr)
		{
			if (DamageHandling == EAIDevMenuDamageHandling::VeryHealthy)
			{
				HealthComp.SetMaxHealth(100000.0, true);
			}
			else if (HealthComp.MaxHealth > 100.0) // Normally this is 1.0
			{
				UBasicAIHealthComponent CDOHealthComp = UBasicAIHealthComponent::Get(Cast<AActor>(Actor.Class.DefaultObject));
				HealthComp.SetMaxHealth(CDOHealthComp.MaxHealth, true);
			}
		}
	}

	bool IsAllBehaviourBlockedInTeam(UHazeTeam Team)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{
			if (!BlockedBehaviorActors.Contains(TeamMember))
				return false;
		}
		return true;
	}

	bool IsAllBehaviourUnblockedInTeam(UHazeTeam Team)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{
			if (BlockedBehaviorActors.Contains(TeamMember))
				return false;
		}
		return true;
	}

	void BlockTeamBehaviour(UHazeTeam Team)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{
			if (!BlockedBehaviorActors.Contains(TeamMember))
			{
				TeamMember.BlockCapabilities(BasicAITags::Behaviour, this);
				BlockedBehaviorActors.Add(TeamMember);
			}
		}
	}

	void UnblockTeamBehaviour(UHazeTeam Team)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{
			if (BlockedBehaviorActors.Contains(TeamMember))
			{
				TeamMember.UnblockCapabilities(BasicAITags::Behaviour, this);
				BlockedBehaviorActors.RemoveSingleSwap(TeamMember);
			}
		}
	}

	bool IsAllMovementBlockedInTeam(UHazeTeam Team)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{
			if (!BlockedMovementActors.Contains(TeamMember))
				return false;
		}
		return true;
	}

	bool IsAllMovementUnblockedInTeam(UHazeTeam Team)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{
			if (BlockedMovementActors.Contains(TeamMember))
				return false;
		}
		return true;
	}

	void BlockTeamMovement(UHazeTeam Team)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{
			if (!BlockedMovementActors.Contains(TeamMember))
			{
				TeamMember.BlockCapabilities(CapabilityTags::Movement, this);
				BlockedMovementActors.Add(TeamMember);
			}
		}
	}

	void UnblockTeamMovement(UHazeTeam Team)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{
			if (BlockedMovementActors.Contains(TeamMember))
			{
				TeamMember.UnblockCapabilities(CapabilityTags::Movement, this);
				BlockedMovementActors.RemoveSingleSwap(TeamMember);
			}
		}
	}

	void UpdateBehaviourRequirementsClaim(FHazeImmediateVerticalBoxHandle Column, UBasicBehaviourComponent BehaviourComp, EBasicBehaviourRequirement Requirement, FString Desc)
	{
		FHazeImmediateHorizontalBoxHandle Row = Column.HorizontalBox();
		if (BehaviourComp.HasClaimedRequirement(Requirement, this))
		{
			if (Row.Button("Resume behaviour " + Desc).BackgroundColor(FLinearColor(0.2, 0.1, 0.1)))
				BehaviourComp.ReleaseSingleRequirement(Requirement, this);
		}
		else if (Row.Button("Pause behaviour " + Desc).BackgroundColor(FLinearColor(0.1, 0.2, 0.1)))
		{
			BehaviourComp.ClaimSingleRequirement(Requirement, 10000, this);			
		}
	}

	void UpdateTeamBehaviourRequirementsClaim(FHazeImmediateVerticalBoxHandle Column, UHazeTeam Team, EBasicBehaviourRequirement Requirement, FString Desc)
	{
		FHazeImmediateHorizontalBoxHandle Row = Column.HorizontalBox();
		bool bAllClaimed = HasClaimedRequirementForAllTeamMembers(Team, Requirement);
		bool bNoneClaimed = HasClaimedRequirementForNoTeamMembers(Team, Requirement);
		if (!bAllClaimed)
		{
			if (Row.Button("Pause behaviour " + Desc).BackgroundColor(FLinearColor((bNoneClaimed ? 0.1 : 0.2), 0.2, 0.1)))
			{
				for (AHazeActor TeamMember : Team.GetMembers())
				{	
					UBasicBehaviourComponent BehaviourComp = (TeamMember != nullptr) ? UBasicBehaviourComponent::Get(TeamMember) : nullptr;
					if (BehaviourComp == nullptr)
						continue; // Skip, there should be some members with a behaviour comp
					BehaviourComp.ClaimSingleRequirement(Requirement, 10000, this);
				}
			}
		}
		if (!bNoneClaimed)
		{
			if (Row.Button("Resume behaviour " + Desc).BackgroundColor(FLinearColor(0.2, (bAllClaimed ? 0.1 : 0.2), 0.1)))
			{
				for (AHazeActor TeamMember : Team.GetMembers())
				{	
					UBasicBehaviourComponent BehaviourComp = (TeamMember != nullptr) ? UBasicBehaviourComponent::Get(TeamMember) : nullptr;
					if (BehaviourComp == nullptr)
						continue; // Skip, there should be some members with a behaviour comp
					BehaviourComp.ReleaseSingleRequirement(Requirement, this);
				}
			}
		}
	}

	bool HasClaimedRequirementForAllTeamMembers(UHazeTeam Team, EBasicBehaviourRequirement Requirement)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{	
			UBasicBehaviourComponent BehaviourComp = (TeamMember != nullptr) ? UBasicBehaviourComponent::Get(TeamMember) : nullptr;
			if (BehaviourComp == nullptr)
				continue; // Skip, there should be some members with a behaviour comp
			if (!BehaviourComp.HasClaimedRequirement(Requirement, this))
				return false;
		}
		return true;
	}

	bool HasClaimedRequirementForNoTeamMembers(UHazeTeam Team, EBasicBehaviourRequirement Requirement)
	{
		for (AHazeActor TeamMember : Team.GetMembers())
		{	
			UBasicBehaviourComponent BehaviourComp = (TeamMember != nullptr) ? UBasicBehaviourComponent::Get(TeamMember) : nullptr;
			if (BehaviourComp == nullptr)
				continue; // Skip, there should be some members with a behaviour comp
			if (BehaviourComp.HasClaimedRequirement(Requirement, this))
				return false;
		}
		return true;
	}

	void SelectNextTeamMember(AHazeActor HazeDebugActor, UBasicBehaviourComponent BehaviourComp)
	{
		UHazeTeam Team = (BehaviourComp != nullptr) ? BehaviourComp.Team : HazeTeam::GetTeam(AITeams::Default);
		TArray<AHazeActor> Members = Team.GetMembers();
		int iMember = Members.FindIndex(HazeDebugActor);
		
		// Select the next valid AI
		for (int i = 1; i < Members.Num() - 1; i++)
		{
			int iNext = (iMember + i) % Members.Num();
			if (!Members.IsValidIndex(iNext))
				continue;
			if (!IsActorValid(Members[iNext]))		
				continue;
			if (UBasicBehaviourComponent::Get(Members[iNext]) == nullptr)
				continue;
			// TODO: Need to expose functionality for this, see SHazeDevMenuContainer::SetSelectedDebugActor
		}
	}
}
