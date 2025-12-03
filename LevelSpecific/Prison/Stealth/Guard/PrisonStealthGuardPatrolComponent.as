/**
 * Attaches to PrisonStealthGuard. A separate component to allow for visualizations.
 */
UCLASS(HideCategories = "Activation Tags")
class UPrisonStealthGuardPatrolComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Since we place splines on the ground we must offset the guard to be mid-air.
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float DistanceFromGround = 300.0;

	// How stiff the location spring is, higher values mean it will reach its target faster.
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float LocationSpringStiffness = 7.0;

	// How much the location spring should be damped 1.0 = critically damped, no overshooting, 0.0 = no damping, max overshooting
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float LocationSpringDamping = 0.3;

	// Max sine wave bob offset max value will be Value and min value will be -Value
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float LocationSineBobAmplitude = 10.0;

	// How long a full sine wave should take
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float LocationSineBobFrequency = 2.0;

	// How stiff the rotation spring is, higher values mean it will reach its target faster.
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float RotationSpringStiffness = 15.0;

	// How much the rotation spring should be damped 1.0 = critically damped, no overshooting, 0.0 = no damping, max overshooting
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float RotationSpringDamping = 0.4;

	// Travel speed over splines.
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float FollowSpeed = 400.0;

	// Frequency of the swiveling rotation when standing still.
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float SwivelFrequency = 2.0;

	UPROPERTY(EditAnywhere, Category = "Sections")
	TArray<FPrisonStealthGuardSection> Sections;

	UPROPERTY(EditAnywhere, Category = "Sections")
	bool bDebugDraw = true;

	APrisonStealthGuard StealthGuard;
	int CurrentSectionIndex = 0;

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		if(!Sections.IsEmpty() && Sections[0].SectionType == EPrisonStealthGuardSectionType::FollowSpline && Sections[0].SplineToFollow.IsValid())
		{
			FTransform ClosestTransform = Sections[0].SplineToFollow.Get().Spline.GetClosestSplineWorldTransformToWorldLocation(Owner.ActorLocation);
			Owner.SetActorLocationAndRotation(ClosestTransform.Location + FVector::UpVector * DistanceFromGround, FQuat::MakeFromZX(FVector::UpVector, ClosestTransform.Rotation.ForwardVector));
		}
	}

	bool HasAnySections() const
	{
		return Sections.Num() > 0;
	}
	
	FPrisonStealthGuardSection GoToNextSection()
	{
		check(HasAnySections());

		CurrentSectionIndex = (CurrentSectionIndex + 1) % Sections.Num();
		return Sections[CurrentSectionIndex];
	}

	FPrisonStealthGuardSection PeekNextSection()
	{
		check(HasAnySections());
		int SectionIndex = (CurrentSectionIndex + 1) % Sections.Num();
		return Sections[SectionIndex];
	}

	FPrisonStealthGuardSection GetCurrentSection() const
	{
		check(HasAnySections());	// Make sure to check this before trying to access Sections
		check(CurrentSectionIndex >= 0 && CurrentSectionIndex < Sections.Num());

		return Sections[CurrentSectionIndex];
	}

	bool GetCurrentSectionIsFollowSpline() const
	{
		const FPrisonStealthGuardSection Section = GetCurrentSection();
		return Section.SectionType == EPrisonStealthGuardSectionType::FollowSpline && Section.HasValidSpline();
	}

	bool GetCurrentSectionIsStandStill() const
	{
		return GetCurrentSection().SectionType == EPrisonStealthGuardSectionType::StandStill;
	}
};

#if EDITOR
class UPrisonStealthGuardPatrolComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPrisonStealthGuardPatrolComponent;

    UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		const auto Component = Cast<UPrisonStealthGuardPatrolComponent>(InComponent);
		if(Component == nullptr)
			return;

		SetRenderForeground(false);

		if(!Component.bDebugDraw)
			return;

		TMap<ASplineActor, int> OverlapCounter;

		AActor Actor = Component.GetOwner();

		FVector Location = Actor.GetActorLocation();
		FRotator Rotation = Actor.GetActorRotation();

		for(int i = 0; i < Component.Sections.Num(); i++)
		{
			const auto& Section = Component.Sections[i];

			if(!Section.bDebugDraw)
				continue;

			switch(Section.SectionType)
			{
				case EPrisonStealthGuardSectionType::FollowSpline:
				{
					if(!Section.SplineToFollow.IsValid())
						continue;

					ASplineActor SplineToFollow = Section.SplineToFollow.Get();

					if(SplineToFollow.Spline == nullptr)
						continue;
					
					UHazeSplineComponent Spline = SplineToFollow.Spline;
					float DistanceAlongSpline = 0.0;
					const float IncrementAmount = 100.0;
					const bool bForward = Section.Direction == EPrisonStealthGuardSplineDir::Forward;

					Location = Spline.GetWorldLocationAtSplineDistance(bForward ? 0.0 : Spline.GetSplineLength());

					// Get how many times we have drawn over this spline
					// This allows us to move each subsequent drawing up somewhat, as to not intersect the previous arrows
					int& Overlaps = OverlapCounter.FindOrAdd(SplineToFollow);
					++Overlaps;

					// Debug draw along spline
					while(DistanceAlongSpline < Spline.GetSplineLength())
					{
						float AlphaDistanceAlongSpline = bForward ? DistanceAlongSpline : Spline.GetSplineLength() - DistanceAlongSpline;
						FVector Start = Spline.GetWorldLocationAtSplineDistance(AlphaDistanceAlongSpline) + FVector(0.0, 0.0, 30.0 * Overlaps);
						DistanceAlongSpline += IncrementAmount;
						AlphaDistanceAlongSpline = bForward ? DistanceAlongSpline : Spline.GetSplineLength() - DistanceAlongSpline;
						FVector End = Spline.GetWorldLocationAtSplineDistance(AlphaDistanceAlongSpline) + FVector(0.0, 0.0, 30.0 * Overlaps);

						DrawArrow(Start, End, Section.DebugColor, 10.0, 1.0);
					}

					Location = Spline.GetWorldLocationAtSplineDistance(bForward ? Spline.GetSplineLength() : 0.0);
					Rotation = Spline.GetWorldRotationAtSplineDistance(bForward ? Spline.GetSplineLength() : 0.0).Rotator();

					break;
				}
				
				case EPrisonStealthGuardSectionType::StandStill:
				{
					const FVector OffsetLocation = Location + FVector(0.0, 0.0, 200.0);
					DrawWireSphere(OffsetLocation, 50.0, Section.DebugColor, 0.5);

					if(Section.bSetWorldYaw)
						Rotation = FRotator(Rotation.Pitch, Section.WorldYaw, Rotation.Roll);

					DrawArrow(OffsetLocation, OffsetLocation + Rotation.ForwardVector * 120.0, Section.DebugColor, 10.0, 2.0);

					// Draw swivel arc
					if(Section.bSetWorldYaw && Section.bSwivelBackAndForth)
					{
						DrawDashedLine(OffsetLocation, OffsetLocation + FRotator(0.0, Section.SwivelAmount, 0.0).RotateVector(Rotation.ForwardVector) * 100.0, Section.DebugColor, 5.0, 1.0);
						DrawDashedLine(OffsetLocation, OffsetLocation + FRotator(0.0, -Section.SwivelAmount, 0.0).RotateVector(Rotation.ForwardVector) * 100.0, Section.DebugColor, 5.0, 1.0);
						DrawArc(OffsetLocation, Section.SwivelAmount * 2.0, 100.0, Rotation.ForwardVector, Section.DebugColor);
					}

					break;
				}
			}
		}
	}
};
#endif