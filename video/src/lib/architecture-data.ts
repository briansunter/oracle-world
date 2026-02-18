export interface ModuleNode {
  id: string;
  label: string;
  sublabel?: string;
  x: number;
  y: number;
  width: number;
  height: number;
  color: string;
  badge?: string;
}

export interface Connection {
  from: string;
  to: string;
  color: string;
}

export const modules: ModuleNode[] = [
  {
    id: "vcn",
    label: "VCN",
    sublabel: "10.0.0.0/16",
    x: 960,
    y: 100,
    width: 200,
    height: 70,
    color: "#3B82F6",
  },
  {
    id: "public-subnet",
    label: "Public Subnet",
    sublabel: "10.0.1.0/24",
    x: 660,
    y: 250,
    width: 220,
    height: 70,
    color: "#06B6D4",
  },
  {
    id: "private-subnet",
    label: "Private Subnet",
    sublabel: "10.0.2.0/24",
    x: 1260,
    y: 250,
    width: 220,
    height: 70,
    color: "#8B5CF6",
    badge: "Optional",
  },
  {
    id: "nlb",
    label: "NLB",
    sublabel: "Stable Public IP",
    x: 460,
    y: 420,
    width: 180,
    height: 70,
    color: "#F59E0B",
  },
  {
    id: "compute",
    label: "ARM Compute",
    sublabel: "A1.Flex \u2022 4 OCPU",
    x: 760,
    y: 420,
    width: 220,
    height: 70,
    color: "#10B981",
  },
  {
    id: "block-storage",
    label: "Block Storage",
    sublabel: "150 GB",
    x: 760,
    y: 570,
    width: 200,
    height: 70,
    color: "#10B981",
  },
  {
    id: "mysql",
    label: "MySQL HeatWave",
    sublabel: "50 GB",
    x: 1260,
    y: 420,
    width: 220,
    height: 70,
    color: "#8B5CF6",
    badge: "Optional",
  },
  {
    id: "object-storage",
    label: "Object Storage",
    sublabel: "S3-Compatible",
    x: 1260,
    y: 570,
    width: 220,
    height: 70,
    color: "#EC4899",
    badge: "Optional",
  },
];

export const connections: Connection[] = [
  { from: "vcn", to: "public-subnet", color: "#3B82F6" },
  { from: "vcn", to: "private-subnet", color: "#3B82F6" },
  { from: "public-subnet", to: "nlb", color: "#06B6D4" },
  { from: "public-subnet", to: "compute", color: "#06B6D4" },
  { from: "nlb", to: "compute", color: "#F59E0B" },
  { from: "compute", to: "block-storage", color: "#10B981" },
  { from: "compute", to: "mysql", color: "#8B5CF6" },
  { from: "private-subnet", to: "mysql", color: "#8B5CF6" },
  { from: "compute", to: "object-storage", color: "#EC4899" },
];
