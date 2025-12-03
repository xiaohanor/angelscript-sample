
struct FWidgetPool
{
	TArray<UPooledWidget> AvailableWidgets;
	TArray<UPooledWidget> FrameActiveWidgets;
	uint LastPoolActivity = 0;
};

class UWidgetPoolComponent : UActorComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostUpdateWork;

	/**
	 * Get a pooled widget of the specified class.
	 * The widget will stay valid until it is returned to the pool by ReturnWidgetToPool()
	 */
	UPooledWidget TakeWidgetFromPool(TSubclassOf<UPooledWidget> WidgetClass, FInstigator Instigator)
	{
		if (WidgetClass.Get() == nullptr)
			return nullptr;

		FWidgetPool& Pool = GetPool(WidgetClass);
		Pool.LastPoolActivity = GFrameNumber;

		if (Pool.AvailableWidgets.Num() != 0)
		{
			for (int i = 0, Count = Pool.AvailableWidgets.Num(); i < Count; ++i)
			{
				UPooledWidget Widget = Pool.AvailableWidgets[i];

				// Ignore widgets that are still animating out
				if (Widget.bIsInDelayedRemove)
				{
					if (!Widget.bReuseDuringRemoveForSameInstigator || Widget.PooledInstigator != Instigator)
						continue;
				}
				else if (Widget.bIsAdded)
				{
					continue;
				}

				if (Widget.bIsInDelayedRemove)
					Widget.FinishRemovingWidget();

				Widget.bIsInPool = false;
				Widget.PoolFrameUsage = GFrameNumber;
				Widget.OnTakenFromPool();

				Pool.AvailableWidgets.RemoveAt(i);
				return Widget;
			}
		}

		// Create a new widget, the pool is empty
		UPooledWidget Widget = Cast<UPooledWidget>(Widget::CreateUserWidget(Cast<AHazePlayerCharacter>(Owner), WidgetClass));
		Widget.bIsInPool = false;
		Widget.PoolFrameUsage = GFrameNumber;
		Widget.OnTakenFromPool();

		return Widget;
	}

	/**
	 * Return a widget that was previously taken from the pool.
	 */
	void ReturnWidgetToPool(UPooledWidget Widget)
	{
		if (Widget == nullptr)
			return;
		FWidgetPool& Pool = GetPool(Widget.Class);
		Pool.LastPoolActivity = GFrameNumber;
		Pool.AvailableWidgets.Add(Widget);

		Widget.bIsInPool = true;
		Widget.PoolFrameUsage = GFrameNumber;
		Widget.OnReturnedToPool();

		// Remove widget from being rendered if it still is
		if (Widget.bIsAdded)
		{
			if (Widget.Player != nullptr)
				Widget.Player.RemoveWidget(Widget);
			else
				Widget::RemoveFullscreenWidget(Widget);
		}
	 }

	/**
	 * Get a pooled widget of the specified class that is only valid for this frame.
	 * If the same instigator does not take a single frame widget again next frame, it is removed.
	 * Single frame widgets should never be manually returned to the pool.
	 */
	UPooledWidget TakeSingleFrameWidget(TSubclassOf<UPooledWidget> WidgetClass, FInstigator Instigator, bool bAddToPlayer = true)
	{
		if (WidgetClass.Get() == nullptr)
			return nullptr;

		FWidgetPool& Pool = GetPool(WidgetClass);

		// First, check if we already have a widget assigned to this instigator
		for (auto Widget : Pool.FrameActiveWidgets)
		{
			if (Widget.PooledInstigator == Instigator)
			{
				Widget.PoolFrameUsage = GFrameNumber;
				return Widget;
			}
		}

		// Create a new widget for this pooled instigator
		UPooledWidget NewWidget = TakeWidgetFromPool(WidgetClass, Instigator);
		NewWidget.PooledInstigator = Instigator;

		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr && bAddToPlayer)
			Player.AddExistingWidget(NewWidget);

		Pool.FrameActiveWidgets.Add(NewWidget);
		return NewWidget;
	}

	private TMap<UClass, FWidgetPool> WidgetPools;
	private FWidgetPool& GetPool(UClass WidgetClass)
	{
		FWidgetPool& Pool = WidgetPools.FindOrAdd(WidgetClass);
		return Pool;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Return widgets that were requested last frame but are no longer valid now
		for (auto Iterator : WidgetPools)
		{
			FWidgetPool& Pool = Iterator.Value;

			// Return single frame widgets to the pool after they aren't requested for a frame
			for (int i = Pool.FrameActiveWidgets.Num() - 1; i >= 0; --i)
			{
				auto FrameWidget = Pool.FrameActiveWidgets[i];
				if (FrameWidget.PoolFrameUsage < GFrameNumber)
				{
					Pool.FrameActiveWidgets.RemoveAtSwap(i);
					ReturnWidgetToPool(FrameWidget);
				}
			}

			if (Pool.LastPoolActivity < GFrameNumber - (60*60))
			{
				// If the pool hasn't been used for a long time, start removing widgets
				Pool.LastPoolActivity = GFrameNumber;
				if (Pool.AvailableWidgets.Num() > 0)
					Pool.AvailableWidgets.RemoveAt(0);

				// If the pool is empty now, delete it
				if (Pool.AvailableWidgets.Num() == 0 && Pool.FrameActiveWidgets.Num() == 0)
					Iterator.RemoveCurrent();
			}
		}
	}

};