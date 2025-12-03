/**
 * Sparse grid of spheres that can be tested for overlap against.
 * Basically just a quad-tree but baked and flattened for performance.
 * 
 * Can only be generated in editor.
 */
struct FStaticSparseSphereGrid
{
	UPROPERTY(NotEditable)
	TArray<float32> Ranges;
	UPROPERTY(NotEditable)
	TArray<int32> Indices;
	UPROPERTY(NotEditable)
	TArray<FVector4f> InstanceBounds;
	UPROPERTY(NotEditable)
	TArray<int32> InstanceData;
	UPROPERTY(NotEditable)
	int XBoxCount = 0;

	int64 GetAllocatedSize() const
	{
		return Ranges.GetAllocatedSize() + Indices.GetAllocatedSize() + InstanceBounds.GetAllocatedSize() + InstanceData.GetAllocatedSize();
	}

	bool HasOverlappingSphere(FVector TestPoint, float TestRadius) const
	{
		int OutInstanceData = -1;
		FVector4f OutInstanceBounds;
		return GetOverlappingSphere(TestPoint, TestRadius, OutInstanceData, OutInstanceBounds);
	}

	bool GetOverlappingSphere(FVector TestPoint, float TestRadius, int& OutInstanceData, FVector4f& OutInstanceBounds, bool bFindHighestInstanceData = false) const
	{
		FScopeCycleCounter CycleCounter(STAT_StaticSparseSphereGrid_GetOverlappingSphere);

		bool bFoundAnyOverlap = false;

		/*for (int32 InstanceIndex = 0, Count = InstanceBounds.Num(); InstanceIndex < Count; ++InstanceIndex)
		{
			const FVector4f& Bounds = InstanceBounds[InstanceIndex];
			float DistanceSQ = Math::Square(Bounds.X - TestPoint.X) + Math::Square(Bounds.Y - TestPoint.Y) + Math::Square(Bounds.Z - TestPoint.Z);
			float MarginSQ = Math::Square(Bounds.W + TestRadius);

			if (DistanceSQ < MarginSQ)
			{
				if (bFindHighestInstanceData)
				{
					if (!bFoundAnyOverlap || OutInstanceData < InstanceData[InstanceIndex])
					{
						OutInstanceData = InstanceData[InstanceIndex];
						OutInstanceBounds = Bounds;
						bFoundAnyOverlap = true;
					}
				}
				else
				{
					// Found an overlap!
					OutInstanceData = InstanceData[InstanceIndex];
					OutInstanceBounds = Bounds;
					return true;
				}
			}
		}
		return bFoundAnyOverlap;*/

		// Find _an_ X-Box that overlaps the test sphere, note that there can be multiple
		float32 TestMin = float32(TestPoint.X - TestRadius);
		float32 TestMax = float32(TestPoint.X + TestRadius);

		int XBoxStartIndex = -1;

		int32 SearchStart = 0;
		int32 SearchEnd = XBoxCount;
		while (SearchStart != SearchEnd)
		{
			int32 PivotIndex = SearchStart + ((SearchEnd - SearchStart) >> 1);
			int32 RangeStartIndex = PivotIndex * 2;

			float32 BoxMin = Ranges[RangeStartIndex];
			float32 BoxMax = Ranges[RangeStartIndex + 1];

			if (TestMax < BoxMin)
			{
				// The test sphere is more to the left
				SearchEnd = PivotIndex;
			}
			else if (TestMin > BoxMax)
			{
				// The test sphere is more to the right
				SearchStart = PivotIndex + 1;
			}
			else
			{
				// This box contains our test sphere
				XBoxStartIndex = PivotIndex;
				break;
			}
		}

		// None of our X-Boxes overlapped the test sphere, we are done
		if (XBoxStartIndex == -1)
			return false;

		// There might be more overlapping boxes to the left
		while (XBoxStartIndex > 0)
		{
			int32 PreviousBoxRangeStart = (XBoxStartIndex - 1) * 2;

			float32 PreviousBoxMax = Ranges[PreviousBoxRangeStart + 1];
			if (TestMin < PreviousBoxMax)
			{
				XBoxStartIndex -= 1;
			}
			else
			{
				break;
			}
		}

		// There might be more overlapping boxes to the right
		int XBoxEndIndex = XBoxStartIndex + 1;
		while (XBoxEndIndex < XBoxCount)
		{
			int32 NextBoxRangeStart = XBoxEndIndex * 2;
			float32 NextBoxMin = Ranges[NextBoxRangeStart];

			if (TestMax > NextBoxMin)
			{
				XBoxEndIndex += 1;
			}
			else
			{
				break;
			}
		}

		// Test against all X-Boxes that can potentially overlap the test sphere
		for (int i = XBoxStartIndex; i < XBoxEndIndex; ++i)
		{
			int32 FirstYBoxIndexInXBox = Indices[i*2];
			int32 EndYBoxIndexInXBox = Indices[i*2 + 1];

			if (FirstYBoxIndexInXBox < 0 || EndYBoxIndexInXBox < 0)
			{
				// Negative indices directly indicate instances, since there are no Y-boxes for this X-box
				for (int32 InstanceIndex = -FirstYBoxIndexInXBox; InstanceIndex < -EndYBoxIndexInXBox; ++InstanceIndex)
				{
					const FVector4f& Bounds = InstanceBounds[InstanceIndex];
					float DistanceSQ = Math::Square(Bounds.X - TestPoint.X) + Math::Square(Bounds.Y - TestPoint.Y) + Math::Square(Bounds.Z - TestPoint.Z);
					float MarginSQ = Math::Square(Bounds.W + TestRadius);

					if (DistanceSQ < MarginSQ)
					{
						if (bFindHighestInstanceData)
						{
							if (!bFoundAnyOverlap || OutInstanceData < InstanceData[InstanceIndex])
							{
								OutInstanceData = InstanceData[InstanceIndex];
								OutInstanceBounds = Bounds;
								bFoundAnyOverlap = true;
							}
						}
						else
						{
							// Found an overlap!
							OutInstanceData = InstanceData[InstanceIndex];
							OutInstanceBounds = Bounds;
							return true;
						}
					}
				}
			}
			else
			{
				// Positive indices indicate we need a search for the correct Y-boxes
				// Find _a_ Y-Box that overlaps the test sphere, note that there can be multiple
				float32 TestMinY = float32(TestPoint.Y - TestRadius);
				float32 TestMaxY = float32(TestPoint.Y + TestRadius);

				int YBoxStartIndex = -1;

				FirstYBoxIndexInXBox += XBoxCount;
				EndYBoxIndexInXBox += XBoxCount;

				SearchStart = FirstYBoxIndexInXBox;
				SearchEnd = EndYBoxIndexInXBox;
				while (SearchStart != SearchEnd)
				{
					int32 PivotIndex = SearchStart + ((SearchEnd - SearchStart) >> 1);
					int32 RangeStartIndex = PivotIndex * 2;

					float32 BoxMin = Ranges[RangeStartIndex];
					float32 BoxMax = Ranges[RangeStartIndex + 1];

					if (TestMaxY < BoxMin)
					{
						// The test sphere is more to the left
						SearchEnd = PivotIndex;
					}
					else if (TestMinY > BoxMax)
					{
						// The test sphere is more to the right
						SearchStart = PivotIndex + 1;
					}
					else
					{
						// This box contains our test sphere
						YBoxStartIndex = PivotIndex;
						break;
					}
				}

				// None of our Y-Boxes overlapped the test sphere
				if (YBoxStartIndex == -1)
					continue;

				// There might be more overlapping boxes to the left
				while (YBoxStartIndex > FirstYBoxIndexInXBox)
				{
					int32 PreviousBoxRangeStart = (YBoxStartIndex - 1) * 2;

					float32 PreviousBoxMax = Ranges[PreviousBoxRangeStart + 1];
					if (TestMinY < PreviousBoxMax)
					{
						YBoxStartIndex -= 1;
					}
					else
					{
						break;
					}
				}

				// There might be more overlapping boxes to the right
				int YBoxEndIndex = YBoxStartIndex + 1;
				while (YBoxEndIndex < EndYBoxIndexInXBox)
				{
					int32 NextBoxRangeStart = YBoxEndIndex * 2;
					float32 NextBoxMin = Ranges[NextBoxRangeStart];

					if (TestMaxY > NextBoxMin)
					{
						YBoxEndIndex += 1;
					}
					else
					{
						break;
					}
				}

				// Test against all Y-Boxes that can potentially overlap the test sphere
				for (int j = YBoxStartIndex; j < YBoxEndIndex; ++j)
				{
					int32 InstanceStartIndex = Indices[j*2];
					int32 InstanceEndIndex = Indices[j*2 + 1];

					for (int32 InstanceIndex = InstanceStartIndex; InstanceIndex < InstanceEndIndex; ++InstanceIndex)
					{
						const FVector4f& Bounds = InstanceBounds[InstanceIndex];
						float DistanceSQ = Math::Square(Bounds.X - TestPoint.X) + Math::Square(Bounds.Y - TestPoint.Y) + Math::Square(Bounds.Z - TestPoint.Z);
						float MarginSQ = Math::Square(Bounds.W + TestRadius);

						if (DistanceSQ < MarginSQ)
						{
							if (bFindHighestInstanceData)
							{
								if (!bFoundAnyOverlap || OutInstanceData < InstanceData[InstanceIndex])
								{
									OutInstanceData = InstanceData[InstanceIndex];
									OutInstanceBounds = Bounds;
									bFoundAnyOverlap = true;
								}
							}
							else
							{
								// Found an overlap!
								OutInstanceData = InstanceData[InstanceIndex];
								OutInstanceBounds = Bounds;
								return true;
							}
						}
					}
				}
			}
		}

		return bFoundAnyOverlap;
	}
};

#if EDITOR
struct FSparseSphereInstance
{
	FVector3f Origin;
	float32 Radius;
	int InstanceData;
}

namespace FStaticSparseSphereGrid
{
	namespace Internal
	{
		struct FSparseSphereSortItem_X
		{
			float32 XCoord;
			int Index;

			int opCmp(FSparseSphereSortItem_X Other) const
			{
				if (XCoord < Other.XCoord)
					return -1;
				else if (XCoord > Other.XCoord)
					return 1;
				else
					return 0;
			}
		};

		struct FSparseSphereSortItem_Y
		{
			float32 YCoord;
			int Index;

			int opCmp(FSparseSphereSortItem_Y Other) const
			{
				if (YCoord < Other.YCoord)
					return -1;
				else if (YCoord > Other.YCoord)
					return 1;
				else
					return 0;
			}
		};

		void Build_GenerateXBoxes(FStaticSparseSphereGrid& Grid, TArray<FSparseSphereInstance> Instances)
		{
			// Sort all the instances by their X coordinate
			TArray<FSparseSphereSortItem_X> Sorted_X;
			Sorted_X.SetNum(Instances.Num());

			for (int i = 0, Count = Instances.Num(); i < Count; ++i)
			{
				Internal::FSparseSphereSortItem_X& Item = Sorted_X[i];
				Item.XCoord = Instances[i].Origin.X;
				Item.Index = i;
			}
			Sorted_X.Sort();

			TArray<float32> YRanges;
			TArray<int32> YIndices;

			Build_EvaluateXBox(Grid, Instances, Sorted_X, 0, Sorted_X.Num(), YRanges, YIndices);

			// Append the Y boxes to the X boxes and calculate the offsets for the X box indices
			Grid.Ranges.Append(YRanges);
			Grid.Indices.Append(YIndices);
		}

		void Build_EvaluateXBox(
			FStaticSparseSphereGrid& Grid,
			TArray<FSparseSphereInstance> Instances,
			TArray<FSparseSphereSortItem_X> Sorted_X,
			int StartIndex, int Count,
			TArray<float32>& YRanges,
			TArray<int32>& YIndices
		)
		{
			if (Count == 0)
				return;

			// Find the center point for all instances in the box
			float32 CenterX = 0.0;
			for (int i = StartIndex; i < StartIndex+Count; ++i)
				CenterX += Sorted_X[i].XCoord / float32(Count);

			int FirstRightIndex = -1;

			float32 TotalMin = MAX_flt;
			float32 TotalMax = -MAX_flt;

			float32 LeftMin = MAX_flt;
			float32 LeftMax = -MAX_flt;

			float32 RightMin = MAX_flt;
			float32 RightMax = -MAX_flt;

			for (int i = StartIndex; i < StartIndex+Count; ++i)
			{
				const FSparseSphereInstance& Instance = Instances[Sorted_X[i].Index];
				float32 Radius = Instance.Radius;
				float32 X = Sorted_X[i].XCoord;

				TotalMin = Math::Min(TotalMin, X - Radius);
				TotalMax = Math::Max(TotalMax, X + Radius);

				if (X < CenterX)
				{
					LeftMin = Math::Min(LeftMin, X - Radius);
					LeftMax = Math::Max(LeftMax, X + Radius);
				}
				else
				{
					RightMin = Math::Min(RightMin, X - Radius);
					RightMax = Math::Max(RightMax, X + Radius);

					if (FirstRightIndex == -1)
						FirstRightIndex = i;
				}
			}

			// If we split along this center point, but the boxes overlap by a lot,
			// then there isn't really a point to splitting, so don't.
			bool bLargeOverlap = false;
			float Overlap = LeftMax - RightMin;
			if (Overlap > (LeftMax - LeftMin) * 0.85)
				bLargeOverlap = true;
			if (Overlap > (RightMax - RightMin) * 0.85)
				bLargeOverlap = true;

			// A low amount of instances never splits
			if (Count <= 4)
			{
				Grid.Ranges.Add(TotalMin);
				Grid.Ranges.Add(TotalMax);

				Grid.Indices.Add(-Grid.InstanceBounds.Num());
				Grid.Indices.Add(-(Grid.InstanceBounds.Num() + Count));
				Grid.XBoxCount += 1;

				for (int i = StartIndex; i < StartIndex+Count; ++i)
				{
					const FSparseSphereInstance& Instance = Instances[Sorted_X[i].Index];
					Grid.InstanceBounds.Add(
						FVector4f(Instance.Origin, Instance.Radius)
					);
					Grid.InstanceData.Add(Instance.InstanceData);
				}
			}
			else if (!bLargeOverlap && Count > Math::CeilToInt(float(Instances.Num() / Math::Sqrt(float(Instances.Num()) / 4.0))))
			{
				Build_EvaluateXBox(Grid, Instances, Sorted_X, StartIndex, FirstRightIndex - StartIndex, YRanges, YIndices);
				Build_EvaluateXBox(Grid, Instances, Sorted_X, FirstRightIndex, Count - (FirstRightIndex - StartIndex), YRanges, YIndices);
			}
			else
			{
				// Add all the instances to the list
				Grid.Ranges.Add(TotalMin);
				Grid.Ranges.Add(TotalMax);
				
				Grid.Indices.Add(Math::IntegerDivisionTrunc(YIndices.Num(), 2));
				Grid.XBoxCount += 1;

				Build_GenerateYBoxes(
					Grid,
					Instances,
					Sorted_X,
					StartIndex,
					Count,
					YRanges,
					YIndices,
				);

				Grid.Indices.Add(Math::IntegerDivisionTrunc(YIndices.Num(), 2));

			}
		}

		void Build_GenerateYBoxes(FStaticSparseSphereGrid& Grid, TArray<FSparseSphereInstance> Instances,
			TArray<FSparseSphereSortItem_X> Sorted_X, int StartIndex_X, int Count_X,
			TArray<float32>& YRanges, TArray<int32>& YIndices)
		{
			// Sort all the instances by their Y coordinate
			TArray<FSparseSphereSortItem_Y> Sorted_Y;
			Sorted_Y.SetNum(Count_X);

			for (int i = StartIndex_X; i < StartIndex_X+Count_X; ++i)
			{
				const FSparseSphereInstance& Instance = Instances[Sorted_X[i].Index];

				Internal::FSparseSphereSortItem_Y& Item = Sorted_Y[i - StartIndex_X];
				Item.YCoord = Instance.Origin.Y;
				Item.Index = Sorted_X[i].Index;
			}

			Sorted_Y.Sort();

			Build_EvaluateYBox(Grid, Instances, Sorted_Y, 0, Sorted_Y.Num(), YRanges, YIndices);
		}

		void Build_EvaluateYBox(
			FStaticSparseSphereGrid& Grid,
			TArray<FSparseSphereInstance> Instances,
			TArray<FSparseSphereSortItem_Y> Sorted_Y,
			int StartIndex, int Count,
			TArray<float32>& YRanges,
			TArray<int32>& YIndices
		)
		{
			// Find the center point for all instances in the box
			float32 CenterY = 0.0;
			for (int i = StartIndex; i < StartIndex+Count; ++i)
				CenterY += Sorted_Y[i].YCoord / float32(Count);

			int FirstRightIndex = -1;

			float32 TotalMin = MAX_flt;
			float32 TotalMax = -MAX_flt;

			float32 LeftMin = MAX_flt;
			float32 LeftMax = -MAX_flt;

			float32 RightMin = MAX_flt;
			float32 RightMax = -MAX_flt;

			for (int i = StartIndex; i < StartIndex+Count; ++i)
			{
				const FSparseSphereInstance& Instance = Instances[Sorted_Y[i].Index];
				float32 Radius = Instance.Radius;
				float32 Y = Sorted_Y[i].YCoord;

				TotalMin = Math::Min(TotalMin, Y - Radius);
				TotalMax = Math::Max(TotalMax, Y + Radius);

				if (Y < CenterY)
				{
					LeftMin = Math::Min(LeftMin, Y - Radius);
					LeftMax = Math::Max(LeftMax, Y + Radius);
				}
				else
				{
					RightMin = Math::Min(RightMin, Y - Radius);
					RightMax = Math::Max(RightMax, Y + Radius);

					if (FirstRightIndex == -1)
						FirstRightIndex = i;
				}
			}

			// Check if we should split this X-Box into two or not
			bool bSplit = true;

			// A low amount of instances never splits
			if (Count <= 4)
				bSplit = false;

			// If we split along this center point, but the boxes overlap by a lot,
			// then there isn't really a point to splitting, so don't.
			float Overlap = LeftMax - RightMin;
			if (Overlap > (LeftMax - LeftMin) * 0.85)
				bSplit = false;
			if (Overlap > (RightMax - RightMin) * 0.85)
				bSplit = false;
			
			// Will cause index out of range
			if (!Math::IsFinite(RightMin) || !Math::IsFinite(RightMax) || !Math::IsFinite(LeftMin) || !Math::IsFinite(LeftMax))
				bSplit = false;

			if (bSplit)
			{
				Build_EvaluateYBox(Grid, Instances, Sorted_Y, StartIndex, FirstRightIndex - StartIndex, YRanges, YIndices);
				Build_EvaluateYBox(Grid, Instances, Sorted_Y, FirstRightIndex, Count - (FirstRightIndex - StartIndex), YRanges, YIndices);
			}
			else
			{
				// Add all the instances to the list
				YRanges.Add(TotalMin);
				YRanges.Add(TotalMax);
				
				YIndices.Add(Grid.InstanceBounds.Num());
				YIndices.Add(Grid.InstanceBounds.Num() + Count);

				for (int i = StartIndex; i < StartIndex+Count; ++i)
				{
					const FSparseSphereInstance& Instance = Instances[Sorted_Y[i].Index];
					Grid.InstanceBounds.Add(
						FVector4f(Instance.Origin, Instance.Radius)
					);
					Grid.InstanceData.Add(Instance.InstanceData);
				}
			}
		}
	}

	FStaticSparseSphereGrid Generate(TArray<FSparseSphereInstance> Instances)
	{
		FStaticSparseSphereGrid Grid;
		Internal::Build_GenerateXBoxes(Grid, Instances);
		return Grid;
	}
}
#endif

const FStatID STAT_StaticSparseSphereGrid_GetOverlappingSphere(n"StaticSparseSphereGrid_GetOverlappingSphere");