struct FTargetableCategoryData
{
	FName Category;
	TArray<UTargetableComponent> Targetables;
	TArray<FHazeComponentSortElement> SortedTargetables;

	TMap<UTargetableComponent, UTargetableWidget> VisibleWidgets;
	uint VisibleWidgetsFrame = 0;

	uint AimRayFrame = 0;
	FAimingRay AimRay;

	FCompletedTargetableQuery PrevQuery;
	uint PrevQueryFrame = 0;
	bool bPrevQueryWasAdHoc = false;
};

struct FCompletedTargetableQuery
{
	bool bValid = false;
	bool bSorted = false;

	int VisibleWidgets = 0;
	float PrimaryScore = 0.0;
	float PrimaryFilterScore = 0.0;
	float PrimaryFilterScoreThreshold = 0.0;
	FTargetableQuery PrimaryTargetable;

	TArray<FStoredTargetableQuery> Queries;
	TArray<UTargetableComponent> Targetables;
};

struct FStoredTargetableQuery
{
	UTargetableComponent Component;
	FTargetableResult Result;

	#if !RELEASE
	TArray<FTargetableQueryTraceDebug> DebugTraces;
	#endif

	void SetFromQuery(FTargetableQuery Query)
	{
		Component = Query.Component;
		Result = Query.Result;

		#if !RELEASE
		DebugTraces = Query.DebugTraces;
		#endif
	}

	int opCmp(const FStoredTargetableQuery& Other) const
	{
		if (!Result.bVisible && Other.Result.bVisible)
			return 1;
		else if (!Other.Result.bVisible && Result.bVisible)
			return -1;
		if (!Result.bPossibleTarget && Other.Result.bPossibleTarget)
			return 1;
		else if (!Other.Result.bPossibleTarget && Result.bPossibleTarget)
			return -1;
		else if (Result.FilterScore < Other.Result.FilterScore - Other.Result.FilterScoreThreshold)
			return 1;
		else if (Result.FilterScore - Result.FilterScoreThreshold > Other.Result.FilterScore)
			return -1;
		else if (Result.Score > Other.Result.Score)
			return -1;
		else if (Result.Score < Other.Result.Score)
			return 1;
		else if (Result.VisualProgress > Other.Result.VisualProgress)
			return -1;
		else if (Result.VisualProgress < Other.Result.VisualProgress)
			return 1;
		else
			return 0;
	}
};

struct FTargetableWidgetSettings
{
	// Filter by category
	FName TargetableCategory;
	// Filter by type of targetable
	TSubclassOf<UTargetableComponent> TargetableClass;
	// Only show at most this many widgets (-1 means infinite)
	int MaximumVisibleWidgets = -1; 
	// If true, only possible targets will have widgets, not visible targets
	bool bOnlyShowWidgetsForPossibleTargets = false;
	// If the targetable component doesn't override the widget, use this widget
	TSubclassOf<UTargetableWidget> DefaultWidget;
	// Any targetables of these classes are ignored for widgets
	TArray<TSubclassOf<UTargetableComponent>> IgnoreTargetableClasses;
	/**
	 * Override which player's screen the targetable widgets show on.
	 * Allows showing widgets for one player on the other player's screen.
	 * 
	 * Note that when in fullscreen, this is always managed automatically by the targetables system.
	 */
	AHazePlayerCharacter OverrideShowWidgetsPlayer;
	// Whether to allow the widget to attach to the edge of the screen
	bool bAllowAttachToEdgeOfScreen = true;
	// Additional offset to where the widgets are located
	FVector AdditionalWidgetOffset;
};

struct FTargetableOutlineSettings
{
	// Filter by category
	FName TargetableCategory;

	// Only show at most this many outlines (-1 means infinite)
	int MaximumOutlinesVisible = 1;

	// If false, all targetable targets will be highlighted. If true, only the primary or highest scoring target will be highlighted, and all else will be treated as if they were just visible.
	bool bOnlyShowOneTarget = false;

	// If false, only targetable targets will be outlined. This depends on the bPossibleTarget and bVisible bools on the query result
	bool bShowVisibleTargets = false;

	// If set to false, the primary target outline will not show up, but will just show as a visible outline instead
	bool bAllowPrimaryTargetOutline = true;
}

class UPlayerTargetablesComponent : UHazeBaseTargetSystemComponent
{
	private TArray<FTargetableCategoryData> Categories;
	private FTargetableQuery DummyQuery;
	private TArray<FName> CategoriesQueriedThisFrame;

	FAimingRay CurrentAimingRay;
	FVector PlayerTargetingInput;

	TInstigated<EPlayerTargetingMode> TargetingMode;
	TInstigated<FVector> TargetingViewLocationOffset;
	TInstigated<FVector> TargetingWidgetLocationOffset;
	TInstigated<bool> IgnoreVisualWidgetDistance;
	default TargetingMode.SetDefaultValue(EPlayerTargetingMode::ThirdPerson);

	UPlayerTargetablesComponent OtherPlayerTargetablesComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		OtherPlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player.OtherPlayer);

#if EDITOR
		TemporalLog::RegisterExtender(Owner, "Targetables", n"TargetableTemporalUIExtender");
#endif
	}

	void UpdateTargeting()
	{
		for (FName Category : CategoriesQueriedThisFrame)
			GetQueryThisFrame(Category, bIsAdHocQuery = false);
		CategoriesQueriedThisFrame.Reset();
	}

	/**
	 * Get the primary component that is currently being targeted in this category.
	 */
	UTargetableComponent GetPrimaryTargetForCategory(FName TargetableCategory)
	{
		auto& Query = GetQueryThisFrame(TargetableCategory);
		return Query.PrimaryTargetable.Component;
	}

	UFUNCTION(BlueprintOverride)
	UActorComponent Internal_GetPrimaryTarget(UClass TargetClass)
	{
		auto TargetableCDO = Cast<UTargetableComponent>(TargetClass.GetDefaultObject());
		auto& Query = GetQueryThisFrame(TargetableCDO.TargetableCategory);

		UTargetableComponent PrimaryComp = Query.PrimaryTargetable.Component;
		if (PrimaryComp == nullptr)
			return nullptr;
		if (PrimaryComp.IsA(TargetClass))
			return PrimaryComp;

		return nullptr;
	}

	/**
	 * Get all currently registered targetables for this type, regardless of their visibility or score.
	 */
	void GetRegisteredTargetables(TSubclassOf<UTargetableComponent> TargetableClass, TArray<UTargetableComponent>&out OutTargetables)
	{
		UClass ClassType = TargetableClass.Get();
		if (ClassType == nullptr)
			return;

		auto TargetableCDO = Cast<UTargetableComponent>(ClassType.GetDefaultObject());
		auto& Category = GetCategory(TargetableCDO.TargetableCategory);
		OutTargetables = Category.Targetables;
	}

	/**
	 * Get all targetables of a particular type that are queried to be visible.
	 * Targetables are returned in sorted order by their score.
	 */
	void GetVisibleTargetables(TSubclassOf<UTargetableComponent> TargetableClass, TArray<UTargetableComponent>&out OutTargetables)
	{
		UClass ClassType = TargetableClass.Get();
		if (ClassType == nullptr)
			return;

		auto TargetableCDO = Cast<UTargetableComponent>(ClassType.GetDefaultObject());
		auto& Query = GetQueryThisFrame(TargetableCDO.TargetableCategory);
		if (!Query.bSorted)
		{
			Query.Queries.Sort();
			Query.bSorted = true;
		}

		for (auto ActiveQuery : Query.Queries)
		{
			if (!ActiveQuery.Result.bVisible)
				continue;
			if (!IsValid(ActiveQuery.Component))
				continue;
			if (!ActiveQuery.Component.IsA(ClassType))
				continue;
			OutTargetables.Add(ActiveQuery.Component);
		}
	}

	/**
	 * Out of all visible targets, return the one with the highest score, as well as the targetable result.
	 * Useful for getting the visual progress.
	 */
	void GetMostVisibleTargetAndResult(TSubclassOf<UTargetableComponent> TargetableClass, UTargetableComponent&out OutTargetable, FTargetableResult&out OutTargetableResult)
	{
		UClass ClassType = TargetableClass.Get();
		if (ClassType == nullptr)
			return;

		auto TargetableCDO = Cast<UTargetableComponent>(ClassType.GetDefaultObject());
		auto& Query = GetQueryThisFrame(TargetableCDO.TargetableCategory);
		if(!Query.bSorted)
		{
			Query.Queries.Sort();
			Query.bSorted = true;
		}

		for(FStoredTargetableQuery ActiveQuery : Query.Queries)
		{
			if(!ActiveQuery.Result.bVisible)
				continue;
			if (!IsValid(ActiveQuery.Component))
				continue;
			if (!ActiveQuery.Component.IsA(ClassType))
				continue;
			OutTargetable = ActiveQuery.Component;
			OutTargetableResult = ActiveQuery.Result;
			return;
		}
	}

	/**
	 * Get all targetables of a particular type that can possibly become the primary targetable.
	 * Targetables with 0 score cannot become primary, and will not be included in this list.
	 * It is possible for invisible targetables to become primary if their score is non-0, and those will be included in this list.
	 * Targetables are returned in sorted order by their score.
	 */
	void GetPossibleTargetables(TSubclassOf<UTargetableComponent> TargetableClass, TArray<UTargetableComponent>&out OutTargetables)
	{
		UClass ClassType = TargetableClass.Get();
		if (ClassType == nullptr)
			return;

		auto TargetableCDO = Cast<UTargetableComponent>(ClassType.GetDefaultObject());
		auto& Query = GetQueryThisFrame(TargetableCDO.TargetableCategory);
		if (!Query.bSorted)
		{
			Query.Queries.Sort();
			Query.bSorted = true;
		}

		for (auto ActiveQuery : Query.Queries)
		{
			if (ActiveQuery.Result.Score <= 0.0)
				continue;
			if (!ActiveQuery.Result.bPossibleTarget)
				continue;
			if (!IsValid(ActiveQuery.Component))
				continue;
			if (!ActiveQuery.Component.IsA(ClassType))
				continue;
			OutTargetables.Add(ActiveQuery.Component);
		}
	}

	/**
	 * Get all currently registered targetables for this type, regardless of their visibility or score.
	 */
	void GetRegisteredTargetables(FName TargetableCategory, TArray<UTargetableComponent>&out OutTargetables)
	{
		auto& Category = GetCategory(TargetableCategory);
		OutTargetables = Category.Targetables;
	}

	/**
	 * Get all targetables of a particular type that are queried to be visible.
	 * Targetables are returned in sorted order by their score.
	 */
	void GetVisibleTargetables(FName TargetableCategory, TArray<UTargetableComponent>&out OutTargetables)
	{
		auto& Query = GetQueryThisFrame(TargetableCategory);
		if (!Query.bSorted)
		{
			Query.Queries.Sort();
			Query.bSorted = true;
		}

		for (auto ActiveQuery : Query.Queries)
		{
			if (!ActiveQuery.Result.bVisible)
				continue;
			if (!IsValid(ActiveQuery.Component))
				continue;
			OutTargetables.Add(ActiveQuery.Component);
		}
	}

	/**
	 * Out of all visible targets, return the one with the highest score, as well as the targetable result.
	 * Useful for getting the visual progress.
	 */
	void GetMostVisibleTargetAndResult(FName TargetableCategory, UTargetableComponent&out OutTargetable, FTargetableResult&out OutTargetableResult)
	{
		auto& Query = GetQueryThisFrame(TargetableCategory);
		if(!Query.bSorted)
		{
			Query.Queries.Sort();
			Query.bSorted = true;
		}

		for(FStoredTargetableQuery ActiveQuery : Query.Queries)
		{
			if(!ActiveQuery.Result.bVisible)
				continue;
			if (!IsValid(ActiveQuery.Component))
				continue;
			OutTargetable = ActiveQuery.Component;
			OutTargetableResult = ActiveQuery.Result;
			return;
		}
	}

	/**
	 * Get all targetables of a particular type that can possibly become the primary targetable.
	 * Targetables with 0 score cannot become primary, and will not be included in this list.
	 * It is possible for invisible targetables to become primary if their score is non-0, and those will be included in this list.
	 * Targetables are returned in sorted order by their score.
	 */
	void GetPossibleTargetables(FName TargetableCategory, TArray<UTargetableComponent>&out OutTargetables)
	{
		auto& Query = GetQueryThisFrame(TargetableCategory);
		if (!Query.bSorted)
		{
			Query.Queries.Sort();
			Query.bSorted = true;
		}

		for (auto ActiveQuery : Query.Queries)
		{
			if (ActiveQuery.Result.Score <= 0.0)
				continue;
			if (!ActiveQuery.Result.bPossibleTarget)
				continue;
			if (!IsValid(ActiveQuery.Component))
				continue;
			OutTargetables.Add(ActiveQuery.Component);
		}
	}

	private FName GetTargetableCategoryFromClass(UClass ClassType)
	{
		if (ClassType == nullptr)
			return NAME_None;
		auto TargetableCDO = Cast<UTargetableComponent>(ClassType.GetDefaultObject());
		if (TargetableCDO == nullptr)
			return NAME_None;
		return TargetableCDO.TargetableCategory;
	}

	private FTargetableCategoryData& GetCategory(FName Category)
	{
		for (FTargetableCategoryData& Data : Categories)
		{
			if (Data.Category == Category)
				return Data;
		}

		FTargetableCategoryData NewData;
		NewData.Category = Category;
		Categories.Add(NewData);

		return Categories[Categories.Num() - 1];
	}

	void RegisterTargetable(FName TargetableCategory, UTargetableComponent Targetable)
	{
		auto& Category = GetCategory(TargetableCategory);
		Category.Targetables.Add(Targetable);
		Sort::AddComponentToList(Category.SortedTargetables, Targetable);
	}

	void UnregisterTargetable(FName TargetableCategory, UTargetableComponent Targetable)
	{
		auto& Category = GetCategory(TargetableCategory);
		Category.Targetables.Remove(Targetable);
		Sort::RemoveComponentFromList(Category.SortedTargetables, Targetable);
	}

	void OverrideTargetableAimRay(TSubclassOf<UTargetableComponent> TargetableClass, FAimingRay Ray)
	{
		OverrideTargetableAimRay(
			GetTargetableCategoryFromClass(TargetableClass.Get()),
			Ray
		);
	}

	void OverrideTargetableAimRay(FName TargetableCategory, FAimingRay Ray)
	{
		auto& Category = GetCategory(TargetableCategory);
		Category.AimRay = Ray;
		Category.AimRayFrame = GFrameNumber;
	}

	FAimingRay GetAimRay(FName TargetableCategory)
	{
		auto& Category = GetCategory(TargetableCategory);
		return Category.AimRay;
	}

	private FCompletedTargetableQuery& GetQueryThisFrame(FName TargetableCategory, bool bIsAdHocQuery = true)
	{
		auto& Category = GetCategory(TargetableCategory);

		// Ad-hoc queries should fall back to the last frame's non-ad-hoc query if we have one
		if (bIsAdHocQuery)
		{
			CategoriesQueriedThisFrame.AddUnique(TargetableCategory);

			// We only do one query for a category per frame
			if (Category.PrevQueryFrame == GFrameNumber)
				return Category.PrevQuery;

			if (Category.PrevQueryFrame == GFrameNumber - 1
				&& !Category.bPrevQueryWasAdHoc)
			{
				return Category.PrevQuery;
			}
		}
		else
		{
			// We only do one query for a category per frame
			if (Category.PrevQueryFrame == GFrameNumber && !Category.bPrevQueryWasAdHoc)
				return Category.PrevQuery;
		}

		// If we queried previous frame, we want to know the primary for that
		UTargetableComponent PreviousPrimary = nullptr;
		if (Category.PrevQuery.bValid && Category.PrevQueryFrame == GFrameNumber - 1)
			PreviousPrimary = Category.PrevQuery.PrimaryTargetable.Component;

		Category.PrevQuery = FCompletedTargetableQuery();
		Category.PrevQuery.bValid = true;
		Category.PrevQueryFrame = GFrameNumber;
		Category.bPrevQueryWasAdHoc = bIsAdHocQuery;

		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if (Category.AimRayFrame < GFrameNumber-1)
			Category.AimRay = CurrentAimingRay;

		FTargetableQuery Query;
		Query.QueryCategory = TargetableCategory;
		Query.TargetingMode = TargetingMode.Get();
		Query.PlayerLocation = Player.ActorLocation;
		Query.ViewLocation = Player.ViewLocation + TargetingViewLocationOffset.Get();
		Query.ViewRotation = Player.ViewRotation;
		Query.ViewForwardVector = Query.ViewRotation.ForwardVector;
		Query.AimRay = Category.AimRay;
		Query.Player = Player;

		auto MoveComp = UHazeMovementComponent::Get(Player);

		// We use the animation input because on the remote side we shouldn't actually care
		// which point is primary, the primary should be sent in capability activation params.
		// So in the end this is just a visual thing for widgets, so we can be inaccurate.
		Query.PlayerMovementInput = MoveComp.GetSyncedMovementInputForAnimationOnly();
		Query.PlayerFacingInputDirection = Player.ActorForwardVector;
		if (Player.HasControl())
		{
			Query.PlayerNonLockedMovementInput = MoveComp.GetNonLockedMovementInput();
			if (!PlayerTargetingInput.IsNearlyZero())
				Query.PlayerTargetingInput = PlayerTargetingInput;
			else
				Query.PlayerTargetingInput = Query.PlayerMovementInput;

			if (MoveComp.HasExplicitTargetFacingRotation())
				Query.PlayerFacingInputDirection = MoveComp.GetExplicitTargetFacingRotation().ForwardVector;
		}
		else
		{
			Query.PlayerNonLockedMovementInput = Query.PlayerMovementInput;
			Query.PlayerTargetingInput = Query.PlayerMovementInput;
		}

		Query.PlayerWorldUp = MoveComp.GetWorldUp();
		Query.PlayerMovementComponent = MoveComp;

		#if !RELEASE
		float StartTime = Time::PlatformTimeSeconds;
		#endif

		Sort::SortByDistanceToPoint(Category.SortedTargetables, Query.PlayerLocation);
		for (const FHazeComponentSortElement& SortElement : Category.SortedTargetables)
		{
			UTargetableComponent Component = Cast<UTargetableComponent>(SortElement.Component);
			if (Component == nullptr)
				continue;

			Query.Component = Component;
			Query.TargetableLocation = Component.WorldLocation;
			Query.bWasPreviousPrimary = (Component == PreviousPrimary);
			Query.DistanceToTargetable = Query.PlayerLocation.Distance(Query.TargetableLocation);
			Query.Result = FTargetableResult();
			Query.bDistanceAppliedToScore = false;
			Query.bHasPerformedTrace = false;
			Query.bHasHandledVisibility = false;

			#if !RELEASE
			Query.DebugTraces.Empty();
			#endif

			// Disabled targetables could still be considered, but have no score
			if (Component.IsDisabledForPlayer(Query.Player))
			{
				Query.Result.Score = 0.0;
				Query.Result.bPossibleTarget = false;
				Query.bIsDisabled = true;
			}
			else
			{
				Query.bIsDisabled = false;
			}

			if (Component.CheckTargetable(Query))
			{
				// Bias very very slightly towards the previous primary target, so if we have two targetables
				// with exactly the same score it doesn't flicker back and forth between them due to precision issues.
				if (!Query.bWasPreviousPrimary)
					Query.Result.Score -= 1e-12;

				// Add to list of all valid targetables
				FStoredTargetableQuery StoredQuery;
				StoredQuery.SetFromQuery(Query);

				Category.PrevQuery.Queries.Add(StoredQuery);
				Category.PrevQuery.Targetables.Add(Component);

				// Check if we should make this the primary targetable
				if (Query.Result.bPossibleTarget)
				{
					if (Query.Result.FilterScore >= Category.PrevQuery.PrimaryFilterScore - Category.PrevQuery.PrimaryFilterScoreThreshold)
					{
						if (Query.Result.Score > Category.PrevQuery.PrimaryScore || Query.Result.FilterScore - Query.Result.FilterScoreThreshold > Category.PrevQuery.PrimaryFilterScore)
						{
							Category.PrevQuery.PrimaryScore = Query.Result.Score;
							Category.PrevQuery.PrimaryFilterScore = Query.Result.FilterScore;
							Category.PrevQuery.PrimaryFilterScoreThreshold = Query.Result.FilterScoreThreshold;
							Category.PrevQuery.PrimaryTargetable = Query;

							Query.CurrentEvalPrimaryTarget = Component;
							Query.CurrentEvalPrimaryScore = Query.Result.Score;
							Query.CurrentEvalPrimaryFilterScore = Category.PrevQuery.PrimaryFilterScore;
							Query.CurrentEvalPrimaryFilterScoreThreshold = Category.PrevQuery.PrimaryFilterScoreThreshold;
						}
					}
				}
			}
			#if EDITOR
			else
			{
				if(Query.Component.bHazeEditorOnlyDebugBool)
				{
					// Log the target even if invalid if it has been marked as debug
					FStoredTargetableQuery StoredQuery;
					StoredQuery.SetFromQuery(Query);

					Category.PrevQuery.Queries.Add(StoredQuery);
					Category.PrevQuery.Targetables.Add(Component);
				}
			}
			#endif

			#if !RELEASE
			// If we have a targetable that's setup to do a trace but not handle visibility
			if (Query.bHasPerformedTrace && !Query.bHasHandledVisibility)
			{
				devError(
					f"Targetable Component {Query.Component.Name} on {Query.Component.Owner.Name} executes a Trace inside its CheckTargetable(),"
					+" but does not apply a visible range using Targetable::ApplyVisibleRange()."
					+"\n\nThis will run traces for every targetable, which will hurt performance."
				);
			}
			#endif
		}

#if !RELEASE
		float EndTime = Time::PlatformTimeSeconds;
		TEMPORAL_LOG(this, Owner, "Targetables").Page("PlayerTargetablesComponent")

			.Point("CurrentAimingRay;Origin", CurrentAimingRay.Origin)
			.DirectionalArrow("CurrentAimingRay;Direction", CurrentAimingRay.Origin, CurrentAimingRay.Direction * 500)
			
			.DirectionalArrow("PlayerTargetingInput", CurrentAimingRay.Origin, PlayerTargetingInput * 500)

			.Value("TargetingMode;Value", TargetingMode.Get())
			.Value("TargetingMode;Instigator", TargetingMode.CurrentInstigator)
			.Value("TargetingMode;Priority", TargetingMode.CurrentPriority)
		;

		if (Category.PrevQuery.PrimaryTargetable.Component != nullptr)
		{
			TEMPORAL_LOG(this, Owner, "Targetables").Page(TargetableCategory.ToString())
				.Value(f"PrimaryTarget", Category.PrevQuery.PrimaryTargetable.Component)
				.Value(f"Score", Category.PrevQuery.PrimaryTargetable.Result.Score)
				.Value(f"Visible", Category.PrevQuery.PrimaryTargetable.Result.bVisible)
			;
		}
		else
		{
			TEMPORAL_LOG(this, Owner, "Targetables").Page(TargetableCategory.ToString())
				.Value(f"PrimaryTarget", nullptr)
				.Value(f"Score", 0.0)
				.Value(f"Visible", false)
			;
		}

		TEMPORAL_LOG(this, Owner, "Targetables").Page(TargetableCategory.ToString())
			.Value(f"TargetableCount", Category.Targetables.Num())
			.Value(f"TraceCount", Query.DebugTraces.Num())
			.Value(f"TargetingMode", f"{Query.TargetingMode :n}")
			.Value(f"QueryTimeMS", (EndTime-StartTime) * 1000.0)
		;

		if(!Category.PrevQuery.bSorted)
			Category.PrevQuery.Queries.Sort();

		for(int TargetIndex = 0; TargetIndex < Category.PrevQuery.Queries.Num(); TargetIndex++)
		{
			const FStoredTargetableQuery& LogQuery = Category.PrevQuery.Queries[TargetIndex];

			bool bShouldLog = false;

			// Log possible targets
			if(LogQuery.Result.bPossibleTarget)
				bShouldLog = true;

			// Log if we did any traces
			if(!LogQuery.DebugTraces.IsEmpty())
				bShouldLog = true;

			#if EDITOR
			// Log if the component is being debugged
			if(LogQuery.Component.bHazeEditorOnlyDebugBool)
				bShouldLog = true;
			#endif

			if(!bShouldLog)
				continue;
			
			FString TargetCategory = f"{TargetIndex :03}#Target {TargetIndex}";

			#if EDITOR
			if(LogQuery.Component.bHazeEditorOnlyDebugBool)
				TargetCategory += " [DEBUG]";
			#endif

			FTemporalLog TemporalLog = TEMPORAL_LOG(this, Owner, "Targetables").Page(TargetableCategory.ToString())
			.Value(f"{TargetCategory};Component", LogQuery.Component)
			.Value(f"{TargetCategory};Visible", LogQuery.Result.bVisible)
			.Value(f"{TargetCategory};Score", LogQuery.Result.Score)
			.Value(f"{TargetCategory};Is Primary", LogQuery.Component == Category.PrevQuery.PrimaryTargetable.Component)
			;

			#if EDITOR
			if(LogQuery.Component.bHazeEditorOnlyDebugBool)
				TemporalLog.Value(f"{TargetCategory};Is Possible", LogQuery.Result.bPossibleTarget);
			#endif

			// Always log traces, since if the target is not possible but is tracing, we might want to investigate that
			for(int TraceIndex = 0; TraceIndex < LogQuery.DebugTraces.Num(); TraceIndex++)
			{
				const FTargetableQueryTraceDebug& Trace = LogQuery.DebugTraces[TraceIndex];
				TemporalLog.HitResults(
					f"{TargetCategory};{TraceIndex :03}#Trace {TraceIndex};{Trace.TraceTag}",
					Trace.Hit, Trace.TraceShape, Trace.ShapeWorldOffset);
			}
		}
#endif	

		return Category.PrevQuery;
	}

	void ShowWidgetsForTargetables(FTargetableWidgetSettings WidgetSettings)
	{
		FName TargetableCategory = WidgetSettings.TargetableCategory;
		if (TargetableCategory.IsNone())
			TargetableCategory = GetTargetableCategoryFromClass(WidgetSettings.TargetableClass);

		FCompletedTargetableQuery& CompleteQuery = GetQueryThisFrame(TargetableCategory);
		if (CompleteQuery.Queries.Num() == 0)
			return;

		AHazePlayerCharacter TargetingPlayer = Cast<AHazePlayerCharacter>(Owner);
		auto WidgetPool = UWidgetPoolComponent::GetOrCreate(TargetingPlayer);

		auto& Category = GetCategory(TargetableCategory);
		Category.VisibleWidgets.Reset();
		Category.VisibleWidgetsFrame = GFrameNumber;

		// We might want to show the widget on a different player's screen than the 
		AHazePlayerCharacter ShowWidgetsPlayer = TargetingPlayer;
		if (WidgetSettings.OverrideShowWidgetsPlayer != nullptr)
			ShowWidgetsPlayer = WidgetSettings.OverrideShowWidgetsPlayer;

		FName CategoryInstigator = TargetableCategory;
		CategoryInstigator.SetNumber(ShowWidgetsPlayer.IsMio() ? 1 : 2);

		int VisibleWidgets = 0;
		if (WidgetSettings.MaximumVisibleWidgets > 0 && !CompleteQuery.bSorted)
		{
			CompleteQuery.Queries.Sort();
			CompleteQuery.bSorted = true;
		}

		for (auto& Query : CompleteQuery.Queries)
		{
			if (Query.Component == nullptr)
				continue;
			if (!Query.Result.bVisible)
				continue;
			if (WidgetSettings.TargetableClass.IsValid() && !Query.Component.IsA(WidgetSettings.TargetableClass))
				continue;
			if (WidgetSettings.IgnoreTargetableClasses.Num() != 0)
			{
				bool bIgnoreTargetable = false;
				for (auto IgnoreClass : WidgetSettings.IgnoreTargetableClasses)
				{
					if (Query.Component.IsA(IgnoreClass))
					{
						bIgnoreTargetable = true;
						break;
					}
				}

				if (bIgnoreTargetable)
					continue;
			}
			if(WidgetSettings.bOnlyShowWidgetsForPossibleTargets && !Query.Result.bPossibleTarget)
				continue;

			UClass WidgetClass = Query.Component.WidgetClass.Get();
			if (WidgetClass == nullptr)
				WidgetClass = WidgetSettings.DefaultWidget;
			if (WidgetClass == nullptr)
				continue;

			FInstigator WidgetInstigator(Query.Component, CategoryInstigator);
			UTargetableWidget Widget = Cast<UTargetableWidget>(WidgetPool.TakeSingleFrameWidget(WidgetClass, WidgetInstigator, bAddToPlayer = false));
			
			Widget.TargetableScore = Query.Result;
			Widget.TargetableCategory = TargetableCategory;
			Widget.UsableByPlayers = Query.Component.UsableByPlayers;
			Widget.bIsPrimaryTarget = (Query.Component == CompleteQuery.PrimaryTargetable.Component);
			Widget.OtherPlayerWidgetState = GetOtherPlayerWidgetState(Query.Component);
			Query.Component.UpdateWidget(Widget, Query.Result);

			Category.VisibleWidgets.Add(Query.Component, Widget);

			if (!Widget.bIsAdded)
				ShowWidgetsPlayer.AddExistingWidget(Widget);
			Widget.AttachWidgetToComponent(Query.Component.GetWidgetAttachComponent(TargetingPlayer, Widget));

			if (WidgetSettings.AdditionalWidgetOffset.IsNearlyZero())
			{
				Widget.SetWidgetRelativeAttachOffset(
					Query.Component.CalculateWidgetVisualOffset(TargetingPlayer, Widget));
			}
			else
			{
				Widget.SetWidgetRelativeAttachOffset(
					Query.Component.CalculateWidgetVisualOffset(TargetingPlayer, Widget)
					+ Query.Component.WorldTransform.InverseTransformVector(WidgetSettings.AdditionalWidgetOffset));
			}

			Widget.SetWidgetShowInFullscreen(true);
			Widget.OnUpdated();

			if (!WidgetSettings.bAllowAttachToEdgeOfScreen)
				Widget.bAttachToEdgeOfScreen = false;

			CompleteQuery.VisibleWidgets += 1;

			#if !RELEASE
			TEMPORAL_LOG(this, Owner, "Targetables").Page(TargetableCategory.ToString())
				.Value(
					f"Widget {CompleteQuery.VisibleWidgets};Widget Class",
					WidgetClass.Name)
				.Value(
					f"Widget {CompleteQuery.VisibleWidgets};Target",
					Query.Component)
				.Value(
					f"Widget {CompleteQuery.VisibleWidgets};Score",
					Query.Result.Score)
				.Value(
					f"Widget {CompleteQuery.VisibleWidgets};bPossibleTarget",
					Query.Result.bPossibleTarget)
				.Value(
					f"Widget {CompleteQuery.VisibleWidgets};VisualProgress",
					Query.Result.VisualProgress)
			;
			#endif

			VisibleWidgets += 1;
			if (WidgetSettings.MaximumVisibleWidgets > 0 && VisibleWidgets >= WidgetSettings.MaximumVisibleWidgets)
				break;
		}
	}

	private UTargetableWidget GetVisibleWidgetForTargetableComponent(UTargetableComponent TargetableComp)
	{
		auto& Category = GetCategory(TargetableComp.TargetableCategory);
		if (Category.VisibleWidgetsFrame < GFrameNumber-1)
			return nullptr;
		if (!Category.VisibleWidgets.Contains(TargetableComp))
			return nullptr;

		UTargetableWidget Widget = Category.VisibleWidgets[TargetableComp];
		if (IsValid(Widget) && Widget.bIsAdded)
			return Widget;
		else
			return nullptr;
	}

	void TriggerActivationAnimationForTargetableWidget(UTargetableComponent TargetableComp)
	{
		UTargetableWidget Widget = GetVisibleWidgetForTargetableComponent(TargetableComp);
		if (Widget != nullptr)
			Widget.BP_OnActivationAnimation();
	}

	private ETargetableWidgetOtherPlayerState GetOtherPlayerWidgetState(UTargetableComponent TargetableComp)
	{
		UTargetableWidget OtherWidget = OtherPlayerTargetablesComponent.GetVisibleWidgetForTargetableComponent(TargetableComp);
		if (OtherWidget != nullptr)
		{
			if (OtherWidget.bIsPrimaryTarget)
				return ETargetableWidgetOtherPlayerState::PrimaryTarget;
			else
				return ETargetableWidgetOtherPlayerState::Visible;
		}

		return ETargetableWidgetOtherPlayerState::NotVisible;
	}

	TArray<UTargetableWidget> GetAllVisibleWidgetsForTargetables(FName TargetableCategory)
	{
		TArray<UTargetableWidget> Widgets;
		auto& Category = GetCategory(TargetableCategory);

		if (Category.VisibleWidgetsFrame < GFrameNumber-1)
		{
			for (auto Elem : Category.VisibleWidgets)
			{
				UTargetableWidget Widget = Elem.Value;
				if (IsValid(Widget) && Widget.bIsAdded)
					Widgets.Add(Widget);
			}
		}

		return Widgets;
	}

	void ShowWidgetsForTargetables(UClass TargetableClass, UClass DefaultWidgetClass = nullptr)
	{
		FTargetableWidgetSettings WidgetSettings;
		WidgetSettings.TargetableClass = TargetableClass;
		WidgetSettings.DefaultWidget = DefaultWidgetClass;
		ShowWidgetsForTargetables(WidgetSettings);
	}

	void ShowWidgetsForTargetables(FName TargetableCategory, UClass DefaultWidgetClass = nullptr)
	{
		FTargetableWidgetSettings WidgetSettings;
		WidgetSettings.TargetableCategory = TargetableCategory;
		WidgetSettings.DefaultWidget = DefaultWidgetClass;
		ShowWidgetsForTargetables(WidgetSettings);
	}

	void ShowOutlinesForTargetables(FTargetableOutlineSettings OutlineSettings)
	{
		FName TargetableCategory = OutlineSettings.TargetableCategory;
		if (TargetableCategory.IsNone())
			return;

		FCompletedTargetableQuery& CompleteQuery = GetQueryThisFrame(TargetableCategory);
		if (CompleteQuery.Queries.Num() == 0)
			return;

		int AppliedOutlines = 0;
		if (OutlineSettings.MaximumOutlinesVisible > 0 && !CompleteQuery.bSorted)
		{
			CompleteQuery.Queries.Sort();
			CompleteQuery.bSorted = true;
		}

		bool bHasShownMainTarget = false;
		auto Player = Cast<AHazePlayerCharacter>(Owner);

		for (auto& Query : CompleteQuery.Queries)
		{
			if (Query.Component == nullptr)
				continue;

			if (!Query.Result.bVisible)
				continue;
			
			bool bIsVisible = Query.Result.bVisible && !Query.Result.bPossibleTarget;
			bool bIsTargetable = (Query.Result.Score > KINDA_SMALL_NUMBER) && Query.Result.bVisible && Query.Result.bPossibleTarget;
			bool bIsPrimaryTarget = (Query.Component == CompleteQuery.PrimaryTargetable.Component);

			if(bHasShownMainTarget && OutlineSettings.bOnlyShowOneTarget)
			{
				bIsTargetable = false;
				bIsPrimaryTarget = false;
				bIsVisible = true;
			}
			
			if(!bIsTargetable && !OutlineSettings.bShowVisibleTargets)
				continue;

			TArray<UTargetableOutlineComponent> OutlineComponents = FindOutlineComponents(Query.Component);
			if(OutlineComponents.IsEmpty())
				continue;

			for(int i = OutlineComponents.Num() - 1; i >= 0; i--)
			{
				auto OutlineComp = OutlineComponents[i];
				if(OutlineComp == nullptr)
				{
					// Outline component was most likely destroyed
					OutlineComponents.RemoveAt(i);
					continue;
				}

				if(bIsTargetable)
				{
					if (!OutlineSettings.bAllowPrimaryTargetOutline)
					{
						OutlineComp.ShowOutlines(Player, ETargetableOutlineType::Visible);
					}
					else if(bIsPrimaryTarget)
					{
						OutlineComp.ShowOutlines(Player, ETargetableOutlineType::Primary);
						bHasShownMainTarget = true;
					}
					else
					{
						OutlineComp.ShowOutlines(Player, ETargetableOutlineType::Target);
					}
				}
				else if(OutlineSettings.bShowVisibleTargets && bIsVisible)
				{
					OutlineComp.ShowOutlines(Player, ETargetableOutlineType::Visible);
				}
			}

			#if !RELEASE
			FTemporalLog TemporalLog = TEMPORAL_LOG(this, Owner, "Targetables").Page(TargetableCategory.ToString());
			const FString OutlineCategory = f"Outline {AppliedOutlines}";

			TemporalLog
				.Value(f"{OutlineCategory};Target", Query.Component)
				.Value(f"{OutlineCategory};Score", Query.Result.Score)
				.Value(f"{OutlineCategory};Is Primary", bIsPrimaryTarget)
				.Value(f"{OutlineCategory};Targetable Category", TargetableCategory)
			;

			for(int i = 0; i < OutlineComponents.Num(); i++)
			{
				const auto OutlineComp = OutlineComponents[i];
				const auto TargetableOutlineData = OutlineComp.GetTargetableOutlineData();
				const FString ComponentCategory = f"{OutlineCategory};Actor {i}: {OutlineComponents[i].Owner}";
				TemporalLog.Value(
					f"{ComponentCategory};Outline Data",
					TargetableOutlineData != nullptr ? TargetableOutlineData.GetPathName() : "No TargetableOutlineData")
				;
			}
			#endif

			AppliedOutlines++;
			if (OutlineSettings.MaximumOutlinesVisible > 0 && AppliedOutlines >= OutlineSettings.MaximumOutlinesVisible)
				break;
		}
	}

	void ClearAllOutlinesForTargetables(FName TargetableCategory)
	{
		TArray<UTargetableComponent> PossibleTargets;
		GetPossibleTargetables(TargetableCategory, PossibleTargets);

		for(auto Target : PossibleTargets)
		{
			const TArray<UTargetableOutlineComponent> OutlineComponents = FindOutlineComponents(Target);
			for(auto OutlineComp : OutlineComponents)
			{
				OutlineComp.ClearOutline();
			}
		}
	}

	private TArray<UTargetableOutlineComponent> FindOutlineComponents(UTargetableComponent Targetable) const
	{
		TArray<UTargetableOutlineComponent> TargetableOutlineComponents;
		Targetable.Owner.GetComponentsByClass(TargetableOutlineComponents);

		TArray<UTargetableOutlineComponent> FoundOutlineComponents;
		UTargetableOutlineComponent BackupOutlineComponent;

		for(auto OutlineComp : TargetableOutlineComponents)
		{
			const UTargetableOutlineDataAsset TargetableOutlineData = OutlineComp.GetTargetableOutlineData();

			if (TargetableOutlineData == nullptr)
				continue;

			if(TargetableOutlineData.TargetableCategory == Targetable.TargetableCategory)
			{
				FoundOutlineComponents.Add(OutlineComp);
				continue;
			}

			if(TargetableOutlineData.TargetableCategory == NAME_None && BackupOutlineComponent == nullptr)
				BackupOutlineComponent = OutlineComp;	// Found a outline with no category, use this in case of no better results
		}

		if(FoundOutlineComponents.IsEmpty())
			FoundOutlineComponents.Add(BackupOutlineComponent);

		return FoundOutlineComponents;
	}
};