class USanctuaryInterfaceComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryInterfaceComponent;

	FLinearColor Color = FLinearColor::Green;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto InterfaceComponent = Cast<USanctuaryInterfaceComponent>(Component);

		FString String = "Listening to: ";
		float StringOffset = 0.0;

		for (auto ListenToActor : InterfaceComponent.ListenToActors)
		{
			auto ListenToActorInterfaceComponent = USanctuaryInterfaceComponent::Get(ListenToActor);
			if (ListenToActorInterfaceComponent != nullptr)
			{
				FVector ArrowDirection = (ListenToActor.ActorLocation - InterfaceComponent.Owner.ActorLocation).SafeNormal;
				DrawArrow(InterfaceComponent.Owner.ActorLocation + ArrowDirection * 80.0, InterfaceComponent.Owner.ActorLocation, Color, 40.0, 5.0);
				DrawDashedLine(ListenToActor.ActorLocation, InterfaceComponent.Owner.ActorLocation, Color, 20.0, 3.0);
			
				String.Append("\n" + ListenToActor.Name);
			}
		
				DrawWorldString(String, InterfaceComponent.Owner.ActorLocation + EditorViewRotation.UpVector * StringOffset, Color, 1.0, 3000.0);
		}
	}
}

event void FSanctuaryInterfaceSignature(AActor Caller);

class USanctuaryInterfaceComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	TArray<AActor> ListenToActors;

	UPROPERTY()
	FSanctuaryInterfaceSignature OnActivated;

	UPROPERTY()
	FSanctuaryInterfaceSignature OnDeactivated;

	FSanctuaryInterfaceSignature OnTriggerActivate;
	FSanctuaryInterfaceSignature OnTriggerDeactivate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto ListenToActor : ListenToActors)
		{
			auto InterfaceComponent = USanctuaryInterfaceComponent::Get(ListenToActor);
			if (InterfaceComponent != nullptr)
			{
				InterfaceComponent.OnTriggerActivate.AddUFunction(this, n"HandleActivate");
				InterfaceComponent.OnTriggerDeactivate.AddUFunction(this, n"HandleDeactivate");
			}
		}
	}

	UFUNCTION()
	private void HandleActivate(AActor Caller)
	{
		OnActivated.Broadcast(Caller);
	}

	UFUNCTION()
	private void HandleDeactivate(AActor Caller)
	{
		OnDeactivated.Broadcast(Caller);
	}

	UFUNCTION()
	void TriggerActivate()
	{
		OnTriggerActivate.Broadcast(Owner);
	}

	UFUNCTION()
	void TriggerDeactivate()
	{
		OnTriggerDeactivate.Broadcast(Owner);
	}
}