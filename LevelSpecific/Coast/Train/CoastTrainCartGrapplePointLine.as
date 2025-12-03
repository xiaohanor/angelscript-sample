class UCoastTrainCartGrapplePointLine : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Line")
	FVector LineStart;

	UPROPERTY(EditAnywhere, Category = "Line")
	FVector LineEnd = FVector(500.0, 0.0, 0.0);

	UPROPERTY(Category = "Settings", EditAnywhere, meta = (ClampMin="0.0"))
	float ActivationRange = 1500.0;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float AdditionalVisibleRange = 800.0;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	float MinimumRange = 0.0;

	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeInput;

	TPerPlayer<UGrapplePointComponent> GrapplePoints;
	TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void EnableGrapplePointLine(FInstigator Instigator)
	{
		DisableInstigators.Remove(Instigator);
		if (DisableInstigators.Num() == 0)
			SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void DisableGrapplePointLine(FInstigator Instigator)
	{
		if (DisableInstigators.Num() == 0)
		{
			for (auto GrappleComp : GrapplePoints)
			{
				if (GrappleComp != nullptr)
					GrappleComp.Disable(this);
			}
			SetComponentTickEnabled(false);
		}

		DisableInstigators.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTransform CartTransform = Owner.ActorTransform;
		FVector CartRight = CartTransform.Rotation.RightVector;

		FTransform LineTransform = WorldTransform;
		FVector LineStartWorld = LineTransform.TransformPosition(LineStart);
		FVector LineEndWorld = LineTransform.TransformPosition(LineEnd);

		bool bOnRightOfCart = (LineStartWorld - CartTransform.Location).DotProduct(CartRight) >= 0.0;

		for (auto Player : Game::Players)
		{
			FVector PlayerLocation = Player.ActorLocation;
			FVector DirectionToPlayer = PlayerLocation - LineStartWorld;

			float DotProduct = DirectionToPlayer.DotProduct(CartRight);
			bool bGrappleUsable = true;

			// Check if the grapple point line is disabled
			if (DisableInstigators.Num() != 0)
				bGrappleUsable = false;

			// Only allow use if the player is away from the cart
			if (bOnRightOfCart)
			{
				if (DotProduct < 10.0)
					bGrappleUsable = false;
			}
			else
			{
				if (DotProduct > -10.0)
					bGrappleUsable = false;
			}

			// Check that we aren't too far or too close from the line
			FVector WantedGrapplePosition;
			if (bGrappleUsable)
			{
				FVector NearestPointOnLine1 = FVector::ZeroVector;
				FVector NearestPointOnLine2 = FVector::ZeroVector;
				FVector ViewLineStart = Player.ViewLocation;
				FVector ViewLineEnd = ViewLineStart + Player.ViewRotation.ForwardVector * 15000.0;

				Math::FindNearestPointsOnLineSegments(
					ViewLineStart, ViewLineEnd, 
					LineStartWorld, LineEndWorld,
					NearestPointOnLine1, NearestPointOnLine2);

				WantedGrapplePosition = Math::ClosestPointOnLine(
					LineStartWorld, LineEndWorld, NearestPointOnLine2
				);
				
				/*if (Player.ActorLocation.Distance(LineStartWorld) > 5000.0)
				{
					Debug::DrawDebugLine(ViewLineStart, ViewLineEnd, FLinearColor::Red, 10);
					Debug::DrawDebugLine(LineStartWorld, LineEndWorld, FLinearColor::Blue, 10);
					Debug::DrawDebugPoint(WantedGrapplePosition, 10, FLinearColor::White);
				}*/

				float GrappleDistance = WantedGrapplePosition.Distance(PlayerLocation);
				if (GrappleDistance > ActivationRange + AdditionalVisibleRange + 100.0)
					bGrappleUsable = false;
				else if (GrappleDistance < MinimumRange)
					bGrappleUsable = false;
			}

			// Create or disable the grapple point if we need to
			if (bGrappleUsable)
			{
				auto GrappleComp = GrapplePoints[Player];
				if (GrappleComp == nullptr)
				{
					FString GrapplePointName = GetName().ToString();
					if (Player.IsMio())
						GrapplePointName += "_Mio";
					else
						GrapplePointName += "_Zoe";
					GrapplePointName += "_GrapplePoint";

					GrappleComp = UGrapplePointComponent::Create(Owner, FName(GrapplePointName));
					GrappleComp.ActivationRange = ActivationRange;
					GrappleComp.AdditionalVisibleRange = AdditionalVisibleRange;
					GrappleComp.MinimumRange = MinimumRange;
					GrappleComp.SetUsableByPlayers(EHazeSelectPlayer(Player.Player));
					GrappleComp.WorldLocation = WantedGrapplePosition;
					GrapplePoints[Player] = GrappleComp;
				}

				// If the player is grappling already we don't change the position
				if (Player.IsAnyCapabilityActive(n"GrappleMovement"))
					WantedGrapplePosition = GrappleComp.WorldLocation;

				if (GrappleComp.IsDisabledForPlayer(Player))
				{
					// First time this is enabled, so snap the location
					GrappleComp.WorldLocation = WantedGrapplePosition;
					GrappleComp.EnableForPlayer(Player, this);
				}
				else
				{
					// Point was already enabled, so we should interp to the new location
					GrappleComp.RelativeLocation = Math::VInterpTo(
						GrappleComp.RelativeLocation,
						GrappleComp.AttachParent.WorldTransform.InverseTransformPosition(WantedGrapplePosition),
						DeltaSeconds, 6.0);
				}
			}
			else
			{
				auto GrappleComp = GrapplePoints[Player];
				if (GrappleComp != nullptr)
					GrappleComp.DisableForPlayer(Player, this);
			}
		}
	}
};

#if EDITOR
class UCoastTrainCartGrapplePointLineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCoastTrainCartGrapplePointLine;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		UCoastTrainCartGrapplePointLine LineComp = Cast<UCoastTrainCartGrapplePointLine>(Component);
		DrawLine(
			LineComp.WorldTransform.TransformPosition(LineComp.LineStart),
			LineComp.WorldTransform.TransformPosition(LineComp.LineEnd),
			FLinearColor::Yellow,
			20.0, true
		);
	}
}
#endif